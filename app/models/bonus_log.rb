class BonusLog < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  validates :reason, presence: true
  validates :bonus_amount, numericality: true
  # validates :source_type, inclusion: { in: %w[Order Ask] }, allow_nil: true

  after_create :update_user_bonus

  private

  def update_user_bonus
    user.update(bonus_balance: user.bonus_balance + bonus_amount)
  end
end
