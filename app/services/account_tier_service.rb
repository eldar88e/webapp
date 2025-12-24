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
    return if new_tier.nil? || user.account_tier_id == new_tier.id

    # rubocop:disable Rails/SkipsModelValidations
    user.update_column(:account_tier_id, new_tier.id)
    # rubocop:enable Rails/SkipsModelValidations
    AccountTierNoticeJob.perform_later(user.id)
  end

  def next_tier
    return AccountTier.first_level if user.account_tier.blank?

    tier = user.account_tier.next
    return unless tier
    return if user.order_count < tier.order_threshold

    tier
  end
end
