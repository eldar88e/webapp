class OrderSerializer < Panko::Serializer
  DELIVERY_COST = 500

  attributes :id, :status, :created_at, :shipped_at, :paid_at, :total_amount, :delivery_cost, :bonus, :bank_card

  has_one :user, serializer: UserSerializer
  has_many :order_items, serializer: OrderItemSerializer

  def bank_card
    "#{object.bank_card.name} #{object.bank_card.fio}" if object.bank_card.present?
  end

  def delivery_cost
    object.has_delivery? ? DELIVERY_COST : 0
  end

  def paid_at
    prepare_date(:paid_at)
  end

  def shipped_at
    prepare_date(:shipped_at)
  end

  def created_at
    prepare_date(:created_at)
  end

  private

  def prepare_date(attribute)
    object.send(attribute)&.in_time_zone('Europe/Moscow')&.strftime('%d.%m.%Y %H:%M:%S')
  end
end
