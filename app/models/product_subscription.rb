class ProductSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :product, counter_cache: :product_subscriptions_count

  validates :user_id, uniqueness: { scope: :product_id, message: I18n.t('errors.messages.subscription') }
end
