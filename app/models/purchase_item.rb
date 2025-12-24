class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def line_total
    quantity * unit_cost
  end
end
