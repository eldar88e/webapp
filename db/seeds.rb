if Rails.env.development?
  User.find_or_create_by!(email: 'eldar@mail.ru') do |user|
    user.tg_id      = 123456
    user.password   = '12345678'
    user.username   = 'test_user'
    user.first_name = 'Test'
    user.role       = 'admin'
    user.started    = true
  end

  user = User.first

  description = "Lorem ipsum dolor sit amet consectetur. Auctor et semper sem nullam egestas viverra. Posuere nibh" \
    " bibendum pulvinar posuere nunc risus sodales nibh. Felis congue est erat scelerisque mi turpis habitant."

  products = [
    { name: 'Маргарита', stock_quantity: 1000, price: 1000, old_price: 1200 },
    { name: 'С курицей', stock_quantity: 0, price: 1800 },
    { name: 'С колбасой', stock_quantity: 50, price: 2100 },
    { name: 'С грибами', stock_quantity: 50, price: 1500 }
  ]

  root_product = Product.find_or_create_by!({ name: 'Товары'})
  product_one  = Product.create!({ name: 'Пицца', ancestry: root_product.id })
  product_two  = Product.create!({ name: 'Пиде', ancestry: root_product.id })
  Product.create!({ name: 'Восточная кухня', ancestry: root_product.id })
  Product.create!({ name: 'Test', ancestry: root_product.id })

  Product.create!({ name: 'Карышык', stock_quantity: 60, price: 2300, ancestry: "#{root_product.id}/#{product_two.id}" })

  products.each do |product|
    product[:description] = description
    product[:ancestry]    = "#{root_product.id}/#{product_one.id}"
    Product.create!(product)
  end

  orders = Order.create!(
    [
      { user_id: user.id, status: :shipped, created_at: 1.month.ago,
        paid_at: 1.month.ago + 1.hour, shipped_at: 1.month.ago + 2.hour },
      { user_id: user.id, status: :shipped, created_at: 2.weeks.ago,
        paid_at: 2.weeks.ago + 1.hour, shipped_at: 2.weeks.ago + 2.hour },
      { user_id: user.id, status: :shipped, created_at: 5.days.ago,
        paid_at: 5.days.ago + 2.hour, shipped_at: 5.days.ago + 4.hour },
      { user_id: user.id, status: :shipped, created_at: 1.days.ago,
        paid_at: 1.days.ago + 2.hour, shipped_at: 1.days.ago + 4.hour },
      { user_id: user.id, status: :shipped, created_at: 1.hour.ago,
        paid_at: 1.hour.ago + 5.minute, shipped_at: 1.hour.ago + 30.minute },
      { user_id: user.id, status: :unpaid, created_at: rand(1..10).days.ago },
      { user_id: user.id, status: :paid, created_at: 12.days.ago, paid_at: rand(1..10).days.ago }
    ])

  products_children = root_product.descendants.where.not(id: root_product.children.ids)

  orders.each do |order|
    count = rand(1..5)
    selected_products = products_children.sample(count)

    selected_products.each do |product|
      OrderItem.create!(order_id: order.id, product_id: product.id, quantity: rand(1..3), price: product.price)
    end

    total_amount = order.order_items.sum("quantity * price")
    order.update!(total_amount: total_amount)
  end

  settings = [
    { variable: 'app_name',	value: 'Test' },
    { variable: 'root_product_id',	value: root_product.id },
    { variable: 'default_product_id',	value: product_one.id },
    { variable: 'delivery_price',	value: 500 },
    { variable: 'tg_main_bot', value: 'tg_main_bot' },
    { variable: 'admin_chat_id' },
    { variable: 'courier_tg_id' },
    { variable: 'admin_ids' },
    { variable: 'tg_token' },
    { variable: 'tg_support' },
    { variable: 'tg_group' },
    { variable: 'preview_msg' },
    { variable: 'spreadsheet_id' },
    { variable: 'group_btn_title', value: 'Группа' },
    { variable: 'bot_btn_title', value: 'Каталог' },
    { variable: 'test_id' },
  ]

  settings.each { |i| Setting.create!(i) }
end
