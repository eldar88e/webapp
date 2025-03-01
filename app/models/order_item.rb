class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :price, presence: true
  validates :product_id, uniqueness: { scope: :order_id, message: I18n.t('errors.messages.already_in_order') }

  def self.total_quantity_sold(start_date, end_date, group_by)
    # .where(orders.status != ?', 5) # 5 == :canceled
    joins(:order)
      .where.not(orders: { status: :canceled })
      .where(orders: { paid_at: start_date..end_date })
      .group(group_by)
      .sum(:quantity)
  end
end
