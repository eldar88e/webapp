FactoryBot.define do
  factory :user do
    email { 'user_1@gmail.com' }
    password { 12345678 }
    tg_id { 12345678 }
  end

  factory :user_two, class: 'User' do
    email { 'user_2@gmail.com' }
    password { 12345678 }
    tg_id { 123456789 }
  end
end
