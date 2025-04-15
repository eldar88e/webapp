FactoryBot.define do
  factory :bank_card do
    name { 'One Bank' }
    fio { 'User User oglu' }
    number { 123_456_789 }
  end
end