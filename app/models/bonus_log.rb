class BonusLog < ApplicationRecord
  belongs_to :user

  validates :reason, presence: true
  validates :bonus_amount, numericality: { greater_than_or_equal_to: 0 }

  after_create :update_user_bonus

  private

  def update_user_bonus
    user.update(bonus_balance: user.bonus_balance + bonus_amount)
  end
end
