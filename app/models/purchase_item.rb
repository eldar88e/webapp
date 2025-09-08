class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :purchase_id }

  def line_total
    quantity * unit_cost
  end
end
