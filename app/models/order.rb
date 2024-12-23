class Order < ApplicationRecord
  ONE_WAIT = 3.hours
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :status, presence: true
  validates :total_amount, presence: true

  enum status: { initialized: 0, unpaid: 1, pending: 2, processing: 3, shipped: 4, cancelled: 5, overdue: 7 } # refunded: 6,

  after_update :check_status_change

  def order_items_with_product
    order_items.includes(:product)
  end

  def self.revenue_by_date(start_date, end_date, group_by)
    joins(:order_items)
      .where(updated_at: start_date..end_date, status: :shipped)
      .group(group_by)
      .sum('order_items.quantity * order_items.price')
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[total_amount updated_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  def order_items_str(courier = false)
    order_items.includes(:product).map do |i|
      next if i.product.name == 'Доставка' && courier

      resust = "• #{i.product.name} — #{i.product.name != 'Доставка' ? (i.quantity.to_s + 'шт.') : 'услуга' }"
      resust += " — #{i.price.to_i}₽" unless courier
      resust
    end.compact.join(",\n")
  end

  private

  # Проверка изменений статуса и выполнение соответствующих действий
  def check_status_change
    case status
    when 'unpaid'
      on_unpaid
    when 'pending'
      on_pending
    when 'processing'
      on_processing
    when 'shipped'
      on_shipped
    when 'cancelled'
      on_cancelled
    when 'refunded'
      on_refunded
    when 'overdue'
      on_overdue
    end
  end

  def on_unpaid
    # Логика для статуса "не оплачен"
    card = Setting.fetch_value(:card)
    msg  = "#{I18n.t('tg_msg.unpaid.msg', order: id)}\n\n"
    msg  += I18n.t(
      'tg_msg.unpaid.main',
      card: card,
      price: total_amount,
      items: order_items_str,
      address: user.full_address,
      postal_code: user.postal_code,
      fio: user.full_name,
      phone: user.phone_number
    )
    TelegramService.delete_msg('', self.user.tg_id, self.msg_id) if self.msg_id
    msg_id = TelegramService.call(msg, self.user.tg_id, markup: 'i_paid')
    self.update_columns(msg_id: msg_id)
    AbandonedOrderReminderJob.set(wait: ONE_WAIT).perform_later(order_id: id, msg_type: :one)
    Rails.logger.info "Order #{id} is now unpaid"
  end

  # Логика для статуса "на этапе проверки платежа"
  def on_pending
    ActiveRecord::Base.transaction do
      self.user.cart.destroy
      msg           = I18n.t(
        'tg_msg.paid_admin',
        order: id,
        price: total_amount,
        items: order_items_str,
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number
      )
      TelegramService.delete_msg('', self.user.tg_id, self.msg_id) if self.msg_id
      TelegramService.call(msg, nil, markup: 'approve_payment') # send to admin
      msg_id = TelegramService.call(I18n.t('tg_msg.paid_client'), user.tg_id) # send client
      update_columns(msg_id: msg_id)
      Rails.logger.info "Order #{id} is now paid"
    end
  end

  # Логика для статуса "в обработке"
  def on_processing
    ActiveRecord::Base.transaction do
      deduct_stock
      msg = I18n.t(
        'tg_msg.on_processing_courier',
        order: id,
        postal_code: user.postal_code,
        items: order_items_str(true),
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number
      )
      TelegramService.call(msg, :courier, markup: 'submit_tracking') # send to deliver
      TelegramService.delete_msg('', user.tg_id, self.msg_id)
      msg_id = TelegramService.call(I18n.t('tg_msg.on_processing_client', order: id), user.tg_id, markup: 'new_order')
      update_columns(msg_id: msg_id)
      Rails.logger.info "Order #{id} is being processed"
    end
  end

  def on_shipped
    # Логика для статуса "отправлен"
    msg = I18n.t(
      'tg_msg.on_shipped_courier',
      order: id,
      price: total_amount,
      items: order_items_str,
      address: user.full_address,
      fio: user.full_name,
      phone: user.phone_number,
      track: tracking_number
    )
    TelegramService.delete_msg('', user.tg_id, self.msg_id)
    msg_id = TelegramService.call(msg, user.tg_id, markup: 'new_order')
    update_columns(msg_id: msg_id)
    Rails.logger.info "Order #{id} has been shipped"
  end

  def on_cancelled
    # Логика для статуса "отменен"
    ActiveRecord::Base.transaction do
      self.order_items.includes(:product).each do |item|
        product = item.product
        next unless product

        product.increment!(:stock_quantity, item.quantity)
      end
    end
    Rails.logger.info "Order #{id} has been cancelled"
    msg = "❌ Заказ #{id} был отменен!\nОстатки были обновлены."
    TelegramService.call msg
    TelegramService.delete_msg('', user.tg_id, self.msg_id)
    TelegramService.call(I18n.t('tg_msg.cancel', order: id), user.tg_id, markup: 'new_order')
  end

  def on_refunded
    # Логика для статуса "возвращен"
    msg = "Order #{id} has been refunded"
    Rails.logger.info msg
    TelegramService.call msg # TODO: шлет уведомление только админу
  end

  def on_overdue
    # Логика для статуса "просрочен"
    Rails.logger.info "Order #{id} has been overdue"
    TelegramService.delete_msg('', user.tg_id, self.msg_id)
    msg    = I18n.t('tg_msg.unpaid.reminder.overdue', order: id)
    msg_id = TelegramService.call(msg, user.tg_id, markup: 'new_order')
    update_columns(msg_id: msg_id)
  end

  def deduct_stock
    order_items.includes(:product).each do |order_item|
      product = order_item.product
      if product.stock_quantity >= order_item.quantity
        product.update!(stock_quantity: product.stock_quantity - order_item.quantity)
      else
        msg = "Недостаток в остатках для продукта: #{product.name} в заказе #{self.id}"
        Rails.logger.info msg
        TelegramService.call(msg)
        raise StandardError, msg
      end
      if product.stock_quantity < 10
        msg = "‼️Осталось #{product.stock_quantity}шт. #{product.name} на складе!"
        Rails.logger.info msg
        TelegramService.call(msg)
      end
    end
  end
end
