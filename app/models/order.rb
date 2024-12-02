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
    TelegramService.delete_msg('', self.user.tg_id, self.msg_id) if self.msg_id
    msg_id = TelegramService.call(I18n.t('tg_msg.unpaid'), self.user.tg_id)
    self.update_columns(msg_id: msg_id)
    Rails.logger.info "Order is now unpaid"
  end

  def on_pending
    # Логика для статуса "оплачен"
    self.user.cart.destroy # удаляем корзину после оплаты
    msg = "Order is now paid"
    TelegramService.call msg # TODO: msg для админа с инфо кто оплатил
    Rails.logger.info msg
  end

  def on_processing
    # Логика для статуса "в обработке"
    msg = "Order is being processed"
    TelegramService.call(msg, 6002481446) # TODO: указать ID курьера
    Rails.logger.info msg
  end

  def on_shipped
    # Логика для статуса "отправлен"
    msg = "Order has been shipped"
    TelegramService.call(msg, self.user.tg_id)
    Rails.logger.info msg
  end

  def on_cancelled
    # Логика для статуса "отменен"
    msg = "Order has been cancelled"
    TelegramService.call msg # TODO: указать ID клиента и админа
    Rails.logger.info msg
  end

  def on_refunded
    # Логика для статуса "возвращен"
    msg = "Order has been refunded"
    TelegramService.call msg # TODO: указать ID клиента и админа
    Rails.logger.info msg
  end
end
