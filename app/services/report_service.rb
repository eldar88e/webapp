class ReportService
  # ONE_WAIT    = 3.hours
  ONE_WAIT     = 10.minutes
  REVIEW_WAIT  = 10.days
  LIMIT_CANCEL = 3

  class << self
    def on_unpaid(order)
      Rails.logger.info "Order #{order.id} is now unpaid"
      payment_transaction = order.payment_transaction || order.create_payment_transaction!(amount: order.total_amount)
      if payment_transaction.status == 'created'
        request_card = Payment::ApiService.order_initialized(payment_transaction)
        if request_card['response'] == 'error'
          raise "Failed to create payment transaction for order #{order.id}: #{request_card['message']}"
        else
          payment_transaction.update!(
            status: :initialized,
            object_token: request_card[:object_token],
            amount_transfer: request_card[:amount_transfer],
            bank_name: request_card[:bank_name],
            card_people: request_card[:fio],
            card_number: request_card[:card_number]
          )
        end
      end

      # TODO: Добавить обработку ошибки в случае ошибок со стороны платежной системы

      user = order.user

      user.cart.destroy

      msg  = "#{I18n.t('tg_msg.unpaid.msg', order: order.id)}\n\n"
      msg += I18n.t(
        'tg_msg.unpaid.main',
        # card: order.bank_card.bank_details,
        card: payment_transaction.card_number,
        bank: payment_transaction.bank_name,
        fio_card: payment_transaction.card_people,
        price: order.total_amount.to_i,
        items: order.order_items_str,
        address: user.full_address,
        postal_code: user.postal_code,
        fio: user.full_name,
        phone: user.phone_number
      )

      # send_report(order, user_msg: msg, user_tg_id: user.tg_id, user_markup: 'i_paid', delete_msg: true)
      delete_old_msg(order)
      msg = user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'i_paid' }, business: true })
      order.update_columns(msg_id: msg.id, tg_msg: false) if msg.present?
      # AbandonedOrderReminderJob.set(wait: ONE_WAIT).perform_async({ 'order_id' => order.id, 'msg_type' => 'one' })
      Payment::ReminderJob.set(wait: ONE_WAIT).perform_later(order_id: order.id, msg_type: 'one')
      Payment::CheckStatusJob.set(wait: 15.seconds).perform_later(payment_transaction.id, 'initialized')
    end

    def on_paid(order)
      Rails.logger.info "Order #{order.id} is now paid"

      payment_transaction = order.payment_transaction
      if payment_transaction.status == 'initialized'
        response = Payment::ApiService.order_process(payment_transaction)
        if response['response'] == 'error'
          raise "Failed to create payment transaction for order #{order.id}: #{response['message']}"
        else
          if response['message'].include?('system_timer_end_merch_initialized_cancel')
            order.update!(status: :overdue)
            payment_transaction.update!(status: :overdue)
          else
            payment_transaction.update!(status: :paid)
            user = order.user
            user_msg = I18n.t('tg_msg.paid_client')
            TelegramMsgDelService.remove(order.user.tg_id, order.msg_id) if order.msg_id.present? && order.tg_msg.present?
            send_report(order, user_msg: user_msg, user_tg_id: user.tg_id, user_markup: 'new_order')

            Payment::CheckStatusJob.set(wait: 15.seconds).perform_later(payment_transaction.id, 'approved')
          end
        end
      end

      # msg  = I18n.t(
      #   'tg_msg.paid_admin',
      #   order: order.id,
      #   card: order.bank_card.bank_details,
      #   price: order.total_amount,
      #   items: order.order_items_str,
      #   address: user.full_address,
      #   fio: user.full_name,
      #   phone: user.phone_number
      # )

      # send_report(order, admin_msg: msg, admin_markup: 'approve_payment',
      #             user_msg: user_msg, user_tg_id: user.tg_id, user_markup: 'new_order')
    end

    def on_processing(order)
      Rails.logger.info "Order #{order.id} is being processed. Payment confirmed."

      user = order.user
      msg  = I18n.t(
        'tg_msg.on_processing_courier',
        order: order.id,
        postal_code: user.postal_code,
        items: order.order_items_str(true),
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number
      )

      user_msg = I18n.t('tg_msg.on_processing_client', order: order.id)
      send_report(order, admin_msg: msg, admin_tg_id: :courier, admin_markup: 'submit_tracking',
                         user_msg: user_msg, user_tg_id: user.tg_id, user_markup: 'new_order', delete_msg: true)
    end

    def on_shipped(order)
      Rails.logger.info "Order #{order.id} has been shipped"

      user = order.user
      msg  = I18n.t(
        'tg_msg.on_shipped_courier',
        order: order.id,
        price: order.total_amount,
        items: order.order_items_str,
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number,
        track: order.tracking_number
      )

      msg_courier = I18n.t('tg_msg.track_num_save', order: order.id, fio: user.full_name, num: order.tracking_number)
      send_report(order, admin_msg: msg_courier, admin_tg_id: :courier,
                         user_msg: msg, user_tg_id: user.tg_id, user_markup: 'new_order', delete_msg: true)
      schedule_review_requests(order, user)
    end

    def on_cancelled(order)
      Rails.logger.info "Order #{order.id} has been cancelled"

      payment_transaction = order.payment_transaction
      if payment_transaction&.status == 'initialized'
        response = Payment::ApiService.order_cancel(payment_transaction)
        if response['response'] == 'error'
          raise "Failed to create payment transaction for order #{order.id}: #{response['message']}"
        else
          order.payment_transaction.update!(status: :cancelled)
        end
      end

      delete_old_msg(order)

      month_cancelled = order.user.orders.where(status: :cancelled, updated_at: Time.current.all_month).count
      admin_msg = "❌ Заказ №#{order.id} был отменен!"
      user_msg  = I18n.t('tg_msg.cancel', order: order.id, limit: "#{LIMIT_CANCEL}/#{month_cancelled}")
      send_report(order, admin_msg: admin_msg, user_msg: user_msg, user_tg_id: order.user.tg_id,
                         user_markup: 'new_order')
    end

    def on_refunded(order)
      msg = "Order №#{order.id} has been refunded"
      Rails.logger.info msg
      TelegramService.call msg
    end

    def on_overdue(order)
      Rails.logger.info "Order #{order.id} has been overdue"
      order.payment_transaction&.update!(status: :overdue)
      delete_old_msg(order)
      user_msg = I18n.t('tg_msg.unpaid.reminder.overdue', order: order.id)
      send_report(order, user_msg: user_msg, user_tg_id: order.user.tg_id, user_markup: 'new_order')
    end

    private

    def delete_old_msg(order)
      return if order.msg_id.blank?

      if order.tg_msg.blank?
        order.user.messages.find_by(id: order.msg_id)&.destroy!
      else
        TelegramMsgDelService.remove(order.user.tg_id, order.msg_id)
      end
    end

    def schedule_review_requests(order, user)
      order.order_items_with_product.each_with_index do |order_item, hours|
        product = order_item.product
        next if user.reviews.exists?(product_id: product.id)

        wait = REVIEW_WAIT + hours.hours
        SendReviewRequestJob.set(wait: wait).perform_later(product_id: product.id, user_id: user.id, order_id: order.id)
      end
    end

    def send_report(order, **args)
      TelegramService.call(args[:admin_msg], args[:admin_tg_id], markup: args[:admin_markup]) if args[:admin_msg]
      TelegramMsgDelService.remove(order.user.tg_id, order.msg_id) if order.msg_id.present? && args[:delete_msg]
      msg_id = TelegramService.call(args[:user_msg], args[:user_tg_id], markup: args[:user_markup])
      return order.update_columns(msg_id: msg_id, tg_msg: true) if msg_id.instance_of?(Integer)

      notify_admin(msg_id, order)
    end

    def notify_admin(error, order)
      Tg::ErrorHandlerService.call(error: error, user: order.user, business: true)
    end
  end
end
