class OrderItemSerializer < Panko::Serializer
  attributes :quantity, :price, :name

  def name
    object.product&.name
  end
end
