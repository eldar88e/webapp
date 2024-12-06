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

  # Колбэки для каждого статуса
  def on_unpaid
    # Логика для статуса "не оплачен"
    TelegramService.delete_msg('', self.user.tg_id, self.msg_id) if self.msg_id # TODO: нужно ли ?
    card = Setting.find_by(variable: 'card').value
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
    admin_chat_id = Setting.find_by(variable: 'admin_chat_id').value
    msg           = I18n.t(
      'tg_msg.paid_admin',
      order: id,
      price: total_amount,
      items: order_items_str,
      address: user.address,
      fio: user.full_name,
      phone: user.phone_number
    )
    TelegramService.call(msg, admin_chat_id, markup: 'approve_payment') # send admin
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
    courier_tg_id = Setting.find_by(variable: 'courier_tg_id').value
    TelegramService.call(msg, courier_tg_id, markup: 'submit_tracking')
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
    TelegramService.call(msg, user.tg_id)
    # TODO: реализовать списание с остатков
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
end
