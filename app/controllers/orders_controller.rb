class OrdersController < ApplicationController
  def index
    @orders = current_user.orders
  end

  def create
    return handle_user_info if params[:page].to_i == 1
    return error_notice('Вы не согласны с нашими условиями!') if params[:user][:agreement] != '1'
    return error_notice(t('required_fields')) unless required_fields_filled?

    update_user
    cart       = current_user.cart
    cart_items = cart.cart_items_with_product
    return redirect_to products_path, alert: 'Ваша корзина пуста' if cart_items.blank?

    create_order(cart, cart_items)

    render turbo_stream: [
      success_notice('Ваш заказ успешно оформлен.'),
      turbo_stream.append(:modal, '<script>closeModal();</script>'.html_safe),
      turbo_stream.append(:modal, '<script>closeMiniApp();</script>'.html_safe)
    ]
  end

  private

  def handle_user_info
    render turbo_stream: turbo_stream.update(:modal, partial: 'orders/user')
    # turbo_stream.append(:modal, "<script>history.pushState(null, null, '/');</script>".html_safe)
  end

  def update_user
    current_user.update(filtered_params) if filtered_params.any?
  end

  def create_order(cart, cart_items)
    cart_product_ids = cart_items.pluck(:product_id)
    ActiveRecord::Base.transaction do
      order = current_user.orders.find_by(status: :unpaid)
      order.order_items.where.not(product_id: cart_product_ids).destroy_all if order
      order = current_user.orders.create!(status: :initialized, total_amount: 0) if order.nil?
      order.update!(total_amount: cart.calculate_total_price, status: :initialized)

      cart_items.each do |cart_item|
        quantity   = calculate_quantity(cart_item)
        order_item = order.order_items_with_product.find_or_initialize_by(product: cart_item.product)
        order_item.destroy! && next if quantity.zero? || quantity.negative?

        order_item.update!(quantity: quantity, price: cart_item.product.price)
      end
      # TODO: Проверить есть ли в заказе товары если нет или есть только доставка удалить order and cart
      order.update!(status: :unpaid)
    end
  end

  def calculate_quantity(cart_item)
    cart_item.product.stock_quantity >= cart_item.quantity ? cart_item.quantity : cart_item.product.stock_quantity
  end
end
