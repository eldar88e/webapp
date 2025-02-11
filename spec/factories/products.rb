FactoryBot.define do
  factory :product do
    name { 'product_1' }
    description { 'product_1_description' }
    price { 100 }
    stock_quantity { 20 }
  end
end
