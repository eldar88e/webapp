class ReportService
  ONE_WAIT    = 3.hours
  REVIEW_WAIT = 10.days

  class << self
    def on_unpaid(order)
      Rails.logger.info "Order #{order.id} is now unpaid"

      user = order.user
      msg  = "#{I18n.t('tg_msg.unpaid.msg', order: order.id)}\n\n"
      msg += I18n.t(
        'tg_msg.unpaid.main',
        card: order.bank_card.bank_details,
        price: order.total_amount,
        items: order.order_items_str,
        address: user.full_address,
        postal_code: user.postal_code,
        fio: user.full_name,
        phone: user.phone_number
      )

      send_report(order, user_msg: msg, user_tg_id: user.tg_id, user_markup: 'i_paid')
      AbandonedOrderReminderJob.set(wait: ONE_WAIT).perform_later(order_id: order.id, msg_type: :one)
    end

    def on_paid(order)
      Rails.logger.info "Order #{order.id} is now paid"

      user = order.user
      msg  = I18n.t(
        'tg_msg.paid_admin',
        order: order.id,
        card: order.bank_card.bank_details,
        price: order.total_amount,
        items: order.order_items_str,
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number
      )

      user_msg = I18n.t('tg_msg.paid_client')
      send_report(order, admin_msg: msg, admin_markup: 'approve_payment', user_msg: user_msg, user_tg_id: user.tg_id)
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
                         user_msg: user_msg, user_tg_id: user.tg_id, user_markup: 'new_order')
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
                         user_msg: msg, user_tg_id: user.tg_id, user_markup: 'new_order')
      schedule_review_requests(order, user)
    end

    def on_cancelled(order)
      Rails.logger.info "Order #{order.id} has been cancelled"

      admin_msg = "❌ Заказ №#{order.id} был отменен!"
      user_msg  = I18n.t('tg_msg.cancel', order: order.id)
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
      user_msg = I18n.t('tg_msg.unpaid.reminder.overdue', order: order.id)
      send_report(order, user_msg: user_msg, user_tg_id: order.user.tg_id, user_markup: 'new_order')
    end

    private

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
      TelegramMsgDelService.remove(order.user.tg_id, order.msg_id) if order.msg_id.present?
      msg_id = TelegramService.call(args[:user_msg], args[:user_tg_id], markup: args[:user_markup])
      return order.update_columns(msg_id: msg_id) if msg_id.instance_of?(Integer)

      notify_admin(msg_id, order.id)
    end

    def notify_admin(error, order_id)
      msg = "Клиенту не пришло бизнес сообщение по заказу #{order_id} по причине"
      if error.message.include?('chat not found')
        TelegramService.call("#{msg} не нажатия на старт!", Setting.fetch_value(:test_id))
      elsif error.message.include?('bot was blocked')
        TelegramService.call("#{msg} добавления им бота в бан!", Setting.fetch_value(:test_id))
      else
        ErrorMailer.send_error("#{msg} #{error.message}", error.full_message).deliver_later
      end
    end
  end
end
