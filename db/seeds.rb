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

  Product.create!({ name: 'Карышык', stock_quantity: 60, price: 2300, ancestry: "#{root_product.id}/#{product_two.id}" })

  products.each do |product|
    product[:description] = description
    product[:ancestry]    = "#{root_product.id}/#{product_one.id}"
    Product.create!(product)
  end

  orders = Order.create!([
                           {
                             user_id: user.id,
                             status: :shipped,
                             updated_at: 1.month.ago,
                             paid_at: 1.month.ago + 1.hour,
                             shipped_at: 1.month.ago + 2.hour,
                           },
                           {
                             user_id: user.id,
                             status: :shipped,
                             updated_at: 2.weeks.ago,
                             paid_at: 2.weeks.ago + 1.hour,
                             shipped_at: 2.weeks.ago + 2.hour,
                           },
                           {
                             user_id: user.id,
                             status: :shipped,
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
    { variable: 'default_product_id',	value: product_one.id },
    { variable: 'delivery_price',	value: 500 },
    { variable: 'tg_main_bot' },
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
