if Rails.env.development?
  User.find_or_create_by!(email: 'test@test.tt') do |user|
    user.password = '12345678'
    user.username = 'Eldar'
  end

  user = User.first

  orders = Order.create!([
    {
      user_id: user.id,
      status: :shipped,
      total_amount: 300,
      updated_at: 1.month.ago
    },
    {
      user_id: user.id,
      status: :shipped,
      total_amount: 150,
      updated_at: 1.month.ago
    },
    {
      user_id: user.id,
      status: :shipped,
      total_amount: 500,
      updated_at: 5.days.ago
    }
  ])

  orders.each do |order|
    2.times do
      product = Product.order("RANDOM()").first
      OrderItem.create!(
        order_id: order.id,
        product_id: product.id,
        quantity: rand(1..5),
        price: product.price
      )
    end
  end
end
