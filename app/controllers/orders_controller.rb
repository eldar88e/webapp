class OrdersController < ApplicationController
  def index
    @orders = current_user.orders
  end

  def create
    return handle_user_info if params[:page].to_i == 1
    return error_notice('Вы не согласны с нашими условиями!') if params[:user][:agreement] != '1'
    return error_notice(t('required_fields')) unless required_fields_filled?

    update_user
    process_order
  end

  private

  def process_order
    service = CreateOrderService.call(current_user)

    if service[:success]
      render turbo_stream: [
        success_notice('Ваш заказ успешно оформлен.'),
        turbo_stream.append(:modal, '<script>closeModal();</script>'.html_safe),
        turbo_stream.append(:modal, '<script>closeMiniApp();</script>'.html_safe)
      ]
    else
      redirect_to products_path, alert: service[:error]
    end
  end

  def handle_user_info
    render turbo_stream: turbo_stream.update(:modal, partial: '/orders/user')
  end

  def update_user
    current_user.update(filtered_params) # TODO: очистить перед сохранением
  end
end
