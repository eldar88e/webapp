class BonusLog < ApplicationRecord
  belongs_to :user

  validates :reason, presence: true
  validates :bonus_amount, numericality: { greater_than_or_equal_to: 0 }
end
