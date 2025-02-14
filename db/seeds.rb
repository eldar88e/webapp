if Rails.env.development?
  User.find_or_create_by!(email: 'test@test.tt') do |user|
    user.tg_id      = 123456
    user.password   = '12345678'
    user.username   = '@test_user'
    user.first_name = 'Test'
    user.role       = 'admin'
  end

  user = User.first

  description = "Lorem ipsum dolor sit amet consectetur. Auctor et semper sem nullam egestas viverra. Posuere nibh" \
    " bibendum pulvinar posuere nunc risus sodales nibh. Felis congue est erat scelerisque mi turpis habitant."

  products = [
    { name: 'Витамин C', stock_quantity: 1000, price: 1000 },
    { name: 'Витамин D', stock_quantity: 0, price: 2000 },
    { name: 'Витамин D', stock_quantity: 50, price: 3000 }
  ]

  root_product = Product.find_or_create_by!({ name: 'Товары'})
  delivery     = Product.create!({ name: 'Доставка', stock_quantity: 999999 })
  vitamins     = Product.create!({ name: 'Витамины', ancestry: root_product.id })
  bads         = Product.create!({ name: 'БАДы', ancestry: root_product.id })

  Product.create!({ name: 'Прополис', stock_quantity: 60, price: 5000, ancestry: "#{root_product.id}/#{bads.id}" })

  products.each do |product|
    product[:description] = description
    product[:ancestry]    = "#{root_product.id}/#{vitamins.id}"
    Product.create!(product)
  end

  orders = Order.create!([
                           {
                             user_id: user.id,
                             status: :shipped,
                             total_amount: 0, # TODO: убрать!
                             updated_at: 1.month.ago,
                             paid_at: 1.month.ago + 1.hour,
                             shipped_at: 1.month.ago + 2.hour,
                           },
                           {
                             user_id: user.id,
                             status: :shipped,
                             total_amount: 0, # TODO: убрать!
                             updated_at: 2.weeks.ago,
                             paid_at: 2.weeks.ago + 1.hour,
                             shipped_at: 2.weeks.ago + 2.hour,
                           },
                           {
                             user_id: user.id,
                             status: :shipped,
                             total_amount: 0, # TODO: убрать!
                             updated_at: 5.days.ago,
                             paid_at: 5.days.ago + 2.hour,
                             shipped_at: 5.days.ago + 4.hour,
                           }
                         ])

  products = root_product.descendants.where.not(id: root_product.children.ids)

  orders.each do |order|
    2.times do
      product = products.sample
      OrderItem.create!(
        order_id: order.id,
        product_id: product.id,
        quantity: rand(1..5),
        price: product.price
      )
      total_amount = order.order_items.sum("quantity * price")
      order.update!(total_amount: total_amount)
    end
  end

  settings = [
    { variable: 'app_name',	value: 'Test' },
    { variable: 'root_product_id',	value: root_product.id },
    { variable: 'default_product_id',	value: vitamins.id },
    { variable: 'delivery_id',	value: delivery.id },
  ]

  settings.each { |i| Setting.create!(i) }
end
