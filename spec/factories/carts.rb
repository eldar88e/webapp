FactoryBot.define do
  factory :cart do
    user { build(:user) }
  end
end
