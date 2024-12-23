if Rails.env.development?
  User.create(
    email: 'test@test.tt',
    password: '12345678',
    username: 'Eldar',
    photo_url: 'https://lh3.googleusercontent.com/ogw/AF2bZygKjbapzeLmtGT_6oQoNtNO4apdp3AxYUVfBzZsoqznVbbm=s64-c-mo'
  )

  user = User.first

  orders = Order.create!([
    {
      user_id: user.id,
      status: :shipped,
      total_amount: 300,
      updated_at: 3.days.ago
    },
    {
      user_id: user.id,
      status: :shipped,
      total_amount: 150,
      updated_at: 5.days.ago
    },
    {
      user_id: user.id,
      status: :shipped,
      total_amount: 500,
      updated_at: 6.days.ago
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
