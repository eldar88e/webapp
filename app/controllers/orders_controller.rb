class OrdersController < ApplicationController
  def index
    @orders = current_user.orders
  end

  def create
    return handle_user_info if params[:page].to_i == 1
    return error_notice("Вы не согласны с нашими условиями!") if params[:user][:agreement] != "1"
    return error_notice("Заполните пожалуйста все обязательные поля!") if filtered_params.size < 6

    update_user
    create_order

    render turbo_stream: [
      success_notice("Ваш заказ успешно оформлен!"),
      turbo_stream.append(:modal, "<script>closeModal();</script>".html_safe),
      turbo_stream.append(:modal, "<script>closeMiniApp();</script>".html_safe)
    ]
  end

  private

    def calculate_total_price(cart)
      cart.cart_items.includes(:product).sum { |item| item.product.price * item.quantity }
    end

    def handle_user_info
      render turbo_stream: turbo_stream.update(:modal, partial: 'orders/user')
      # turbo_stream.append(:modal, "<script>history.pushState(null, null, '/');</script>".html_safe)
    end

    def user_params
      params.require(:user).permit(:first_name, :middle_name, :last_name, :address, :phone_number, :postal_code)
    end

    def filtered_params
      user_params.to_h.reject { |_key, value| value.blank? }
    end

    def update_user
      current_user.update(filtered_params) if filtered_params.any?
    end

    def create_order
      cart  = current_user.cart
      order = current_user.orders.find_or_create_by(status: :unpaid)
      order.update!(total_amount: calculate_total_price(cart))

      cart.cart_items.each do |cart_item|
        order_item = order.order_items.find_or_create_by(product: cart_item.product)
        order_item.update(quantity: cart_item.quantity, price: cart_item.product.price)
      end
    end
end
