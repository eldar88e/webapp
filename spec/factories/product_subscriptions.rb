FactoryBot.define do
  factory :product_subscription do
    user { build(:user) }
    product { build(:product) }
  end
end