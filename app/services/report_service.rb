class ReportService
  ONE_WAIT = 3.hours
  REVIEW_WAIT = 1.minute # 10.days

  class << self
    def on_unpaid(order)
      Rails.logger.info "Order #{order.id} is now unpaid"

      card = Setting.fetch_value(:card)
      user = order.user
      msg  = "#{I18n.t('tg_msg.unpaid.msg', order: order.id)}\n\n"
      msg += I18n.t(
        'tg_msg.unpaid.main',
        card: card,
        price: order.total_amount,
        items: order.order_items_str(order),
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
        price: order.total_amount,
        items: order.order_items_str,
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number
      )

      user.cart.destroy
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

      order.deduct_stock
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
      schedule_review_requests(order)
    end

    def on_cancelled(order)
      Rails.logger.info "Order #{order.id} has been cancelled"

      order.order_items_with_product.each do |item|
        product = item.product
        next unless product

        product.increment!(:stock_quantity, item.quantity)
      end

      admin_msg = "❌ Заказ #{order.id} был отменен!\nОстатки были обновлены."
      user_msg  = I18n.t('tg_msg.cancel', order: order.id)
      send_report(order, admin_msg: admin_msg, user_msg: user_msg, user_tg_id: order.user.tg_id, user_markup: 'new_order')
    end

    def on_refunded(order)
      msg = "Order #{order.id} has been refunded"
      Rails.logger.info msg

      telegram_send_msg msg # TODO: шлет уведомление только админу
    end

    def on_overdue(order)
      Rails.logger.info "Order #{order.id} has been overdue"

      user_msg = I18n.t('tg_msg.unpaid.reminder.overdue', order: order.id)
      send_report(order, user_msg: user_msg, user_tg_id: order.user.tg_id, user_markup: 'new_order')
    end
  end

  private

  def self.schedule_review_requests(order)
    user = order.user
    order.order_items.includes(:product).each do |order_item|
      product = order_item.product
      next if product.id == Setting.fetch_value(:delivery_id).to_i

      unless user.reviews.exists?(product_id: product.id)
        SendReviewRequestJob.set(wait: REVIEW_WAIT).perform_later(product_id: product.id, user_id: user.id)
      end
    end
  end

  def self.send_report(order, **args)
    telegram_send_msg(args[:admin_msg], args[:admin_tg_id], args[:admin_markup]) if args[:admin_msg]
    telegram_delete_msg(order)
    msg_id = telegram_send_msg(args[:user_msg], args[:user_tg_id], args[:user_markup])
    order.update_columns(msg_id: msg_id)
  end

  def self.telegram_delete_msg(order)
    return if order.msg_id.blank?

    TelegramService.delete_msg('', order.user.tg_id, order.msg_id)
  rescue => e
    Rails.logger.error "Error deleting telegram msg. #{e.message}"
  end

  def self.telegram_send_msg(msg, id = nil, markup = nil)
    return TelegramService.call(msg, id, markup: markup) if markup

    TelegramService.call(msg, id)
  rescue => e
    Rails.logger.error "Error sending telegram msg. #{e.message}"
  end
end
