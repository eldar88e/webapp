class Expense < ApplicationRecord
  include ExchangeRate

  belongs_to :expenseable, polymorphic: true, optional: true

  enum :category, { advertising: 0, logistics: 1, other: 2 }

  validates :category, :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }

  before_validation :set_category, :set_first_exchange_rate

  after_create :set_exchange_rate

  private

  def set_category
    return if category.present? || expenseable_type != 'Purchase'

    self.category = :logistics
  end

  def set_first_exchange_rate
    self.exchange_rate = Setting.fetch_value(:try).to_f
  end
end
