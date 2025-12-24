class AccountTierService
  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    user.with_lock do
      increment_order_count!
      upgrade_account_tier_if_needed
    end
  end

  private

  attr_reader :user

  def increment_order_count!
    # rubocop:disable Rails/SkipsModelValidations
    user.increment!(:order_count)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def upgrade_account_tier_if_needed
    new_tier = next_tier
    return unless new_tier

    # rubocop:disable Rails/SkipsModelValidations
    user.update_column(:account_tier_id, new_tier.id)
    # rubocop:enable Rails/SkipsModelValidations
    AccountTierNoticeJob.perform_later(user.id)
  end

  def next_tier
    tier = user.next_account_tier
    tier.nil? || user.order_count < tier.order_threshold ? nil : tier
  end
end
