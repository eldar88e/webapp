FactoryBot.define do
  factory :order do
    user { build(:user) }
    total_amount { 100 }
    status { :unpaid }

    trait :with_items do
      after(:create) do |order|
        create_list(:order_item, 2, order: order)
      end
    end
  end
end
