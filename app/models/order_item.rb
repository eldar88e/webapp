class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :price, presence: true
  validates :product_id, uniqueness: { scope: :order_id, message: 'уже добавлен в этот заказ' }

  def self.total_quantity_sold(start_date, end_date, group_by)
    # .where.not(product_id: Setting.fetch_value(:delivery_id), orders: { status: :canceled })
    joins(:order)
      .where('product_id != ? AND orders.status != ?', Setting.fetch_value(:delivery_id).to_i, 5) # 5 == :canceled
      .where(orders: { paid_at: start_date..end_date })
      .group(group_by)
      .sum(:quantity)
  end
end
