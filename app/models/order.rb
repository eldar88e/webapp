class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :status, presence: true
  validates :total_amount, presence: true

  enum status: { initialized: 0, unpaid: 1, pending: 2, processing: 3, shipped: 4, cancelled: 5, refunded: 6 }

  after_update :check_status_change
  after_create :on_unpaid

  def order_items_with_product
    order_items.includes(:product)
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
    end
  end

  def on_unpaid
    # Логика для статуса "не оплачен"
    TelegramService.delete_msg('', self.user.tg_id, self.msg_id) if self.msg_id
    card  = Setting.fetch_value(:card)
    msg   = I18n.t(
      'tg_msg.unpaid',
      order: id,
      card: card,
      price: total_amount,
      items: order_items_str,
      address: user.full_address,
      fio: user.full_name,
      phone: user.phone_number
    )
    msg_id = TelegramService.call(msg, self.user.tg_id, markup: 'i_paid')
    self.update_columns(msg_id: msg_id)
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
        items: order_items_str,
        address: user.full_address,
        fio: user.full_name,
        phone: user.phone_number
      )
      TelegramService.call(msg, :courier, markup: 'submit_tracking') # send to deliver
      TelegramService.delete_msg('', user.tg_id, self.msg_id)
      msg_id = TelegramService.call(I18n.t('tg_msg.on_processing_client', order: id), user.tg_id)
      update_columns(msg_id: msg_id)
      Rails.logger.info "Order #{id} is being processed"
    end
  end

  def on_shipped
    # Логика для статуса "отправлен"
    TelegramService.delete_msg('', user.tg_id, self.msg_id)
    msg = I18n.t('tg_msg.on_shipped_courier',
                 order: id,
                 price: total_amount,
                 items: order_items_str,
                 address: user.full_address,
                 fio: user.full_name,
                 phone: user.phone_number,
                 track: tracking_number
    )
    TelegramService.call(msg, user.tg_id)
    Rails.logger.info "Order #{id} has been shipped"
  end

  def on_cancelled
    # Логика для статуса "отменен"
    msg = "Order #{id} has been cancelled"
    TelegramService.call msg # TODO: шлет уведомление только админу
    Rails.logger.info msg
  end

  def on_refunded
    # Логика для статуса "возвращен"
    msg = "Order #{id} has been refunded"
    TelegramService.call msg # TODO: шлет уведомление только админу
    Rails.logger.info msg
  end

  def order_items_str
    order_items.includes(:product).map.with_index(1) do |i, idx|
      "#{idx}. #{i.product.name} #{i.product.name != 'Доставка' ? (i.quantity.to_s + 'шт.') : 'услуга' } #{i.price}₽"
    end.join(",\n")
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
