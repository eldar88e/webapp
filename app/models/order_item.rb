class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :price, presence: true
  validates :product_id, uniqueness: { scope: :order_id, message: 'уже добавлен в этот заказ' }
end
