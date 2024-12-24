class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true

  def self.total_quantity_sold(start_date, end_date, group_by)
    joins(:order)
      .where(orders: { updated_at: start_date..end_date, status: :shipped })
      .group(group_by)
      .sum(:quantity)
  end
end
