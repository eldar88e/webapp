class AccountTier < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :title, presence: true, uniqueness: true
  validates :order_threshold, numericality: { greater_than_or_equal_to: 0 }
  validates :bonus_percentage, numericality: { greater_than_or_equal_to: 0 }
  # validates :order_min_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :first_level, -> { order(:order_threshold).first }

  def next
    AccountTier.where('order_threshold > ?', order_threshold).order(:order_threshold).first
  end
end
