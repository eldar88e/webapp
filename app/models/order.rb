class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :status, presence: true
  validates :total_amount, presence: true

  enum status: { unpaid: 0, pending: 1, processing: 2, shipped: 3, cancelled: 4, refunded: 5 }

  after_update :check_status_change
  after_create :on_unpaid

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
    card = Setting.find_by(variable: 'card').value # TODO: через cache
    msg  = I18n.t(
      'tg_msg.unpaid',
      order: id,
      card: card,
      price: total_amount,
      items: order_items_str(user.cart.cart_items),
      address: user.address,
      fio: user.full_name,
      phone: user.phone_number
    )
    msg_id = TelegramService.call(msg, self.user.tg_id, markup: 'i_paid')
    self.update_columns(msg_id: msg_id)
    Rails.logger.info "Order #{id} is now unpaid"
  end

  def on_pending # is paid and on pending
    # Логика для статуса "оплачен"
    self.user.cart.destroy # удаляем корзину после оплаты
    msg           = I18n.t(
      'tg_msg.paid_admin',
      order: id,
      price: total_amount,
      items: order_items_str,
      address: user.address,
      fio: user.full_name,
      phone: user.phone_number
    )
    TelegramService.call(msg, nil, markup: 'approve_payment') # send to admin
    msg_id = TelegramService.call(I18n.t('tg_msg.paid_client'), user.tg_id) # send client
    update_columns(msg_id: msg_id)
    Rails.logger.info "Order #{id} is now paid"
  end

  def on_processing
    # Логика для статуса "в обработке"
    msg = I18n.t(
      'tg_msg.on_processing_courier',
      order: id,
      postal_code: user.postal_code,
      items: order_items_str,
      address: user.address,
      fio: user.full_name,
      phone: user.phone_number
    )
    TelegramService.call(msg, :courier, markup: 'submit_tracking') # send to deliver
    TelegramService.delete_msg('', user.tg_id, self.msg_id)
    msg_id = TelegramService.call(I18n.t('tg_msg.on_processing_client', order: id), user.tg_id)
    update_columns(msg_id: msg_id)
    Rails.logger.info "Order #{id} is being processed"
  end

  def on_shipped
    # Логика для статуса "отправлен"
    TelegramService.delete_msg('', user.tg_id, self.msg_id)
    msg = I18n.t('tg_msg.on_shipped_courier',
                 order: id,
                 price: total_amount,
                 items: order_items_str,
                 address: user.address,
                 fio: user.full_name,
                 phone: user.phone_number,
                 track: tracking_number
    )
    deduct_stock
    TelegramService.call(msg, user.tg_id)
    Rails.logger.info "Order #{id} has been shipped"
  end

  def on_cancelled
    # Логика для статуса "отменен"
    msg = "Order #{id} has been cancelled"
    TelegramService.call msg # TODO: указать ID клиента и админа
    Rails.logger.info msg
  end

  def on_refunded
    # Логика для статуса "возвращен"
    msg = "Order #{id} has been refunded"
    TelegramService.call msg # TODO: указать ID клиента и админа
    Rails.logger.info msg
  end

  def order_items_str(items = nil)
    (items || order_items).map.with_index(1) do |i, idx|
      "#{idx}. #{i.product.name} #{i.product.name != 'Доставка' ? (i.quantity.to_s + 'шт.') : 'услуга' } #{items ? i.product.price : i.price}₽"
    end.join(",\n")
  end

  def deduct_stock
    order_items.each do |order_item|
      product = order_item.product
      if product.stock_quantity >= order_item.quantity
        product.update!(stock_quantity: product.stock_quantity - order_item.quantity)
      else
        msg = "Insufficient stock for product: #{product.name}"
        Rails.logger.info msg
        TelegramService.call(msg)
        raise StandardError, msg
      end
      if product.stock_quantity < 10
        msg = "Осталось #{product.stock_quantity}шт. #{product.name} на складе!"
        Rails.logger.info msg
        TelegramService.call(msg)
      end
    end
  end
end
