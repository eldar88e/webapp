if Rails.env.development?
  user_one = User.find_or_create_by!(email: 'user_test@mail.ru') do |u|
    u.tg_id      = 123456
    u.password   = '12345678'
    u.username   = 'test_user'
    u.first_name = 'Test'
    u.role       = 'admin'
    u.started    = true
  end

  user_two = User.find_or_create_by!(email: 'user@mail.ru') do |u|
    u.tg_id      = 1234567
    u.password   = '12345678'
    u.username   = 'test2_user'
    u.first_name = 'Test 2'
    u.role       = 'user'
    u.started    = true
  end

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

  orders = []
  [user_one, user_two].each do |user|
    result = Order.create!(
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
    orders += result
  end

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

  [user_one, user_two].each do |user|
    product = user.orders.sample.order_items.sample.product
    user.reviews.create!(product: product, rating: rand(1..4), content: 'Все очень вкусно', approved: true)
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
    { variable: 'preview_msg', value: 'Текст приветствия!' },
    { variable: 'spreadsheet_id' },
    { variable: 'group_btn_title', value: 'Группа' },
    { variable: 'bot_btn_title', value: 'Каталог' },
    { variable: 'test_id' },
    { variable: 'bonus_threshold', value: 5_000 },
  ]

  settings.each { |i| Setting.create!(i) }

  BankCard.create!(name: 'One bank', fio: 'Name', number: 123)

  AccountTier.create!(
    [{ title: 'silver', order_threshold: 1, bonus_percentage: 1, order_min_amount: 2000 },
     { title: 'gold', order_threshold: 5, bonus_percentage: 3, order_min_amount: 2000 },
     { title: 'vip', order_threshold: 11, bonus_percentage: 5, order_min_amount: 2000 },
    ]
  )

  puts 'Finished!'
end
