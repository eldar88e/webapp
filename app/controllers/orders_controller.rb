class OrdersController < ApplicationController
  def index
    @orders = current_user.orders.order(updated_at: :desc)
  end

  def show
    @order = current_user.orders.includes(order_items: { product: :image_attachment }).find(params[:id])
    render turbo_stream: turbo_stream.update('modal-block', partial: '/orders/show', locals: { order: @order })
  end

  def create
    return error_notice(t('.agreement')) if params[:user][:agreement] != '1'
    return error_notice(t('.required_fields')) unless required_fields_filled?
    return process_order if update_user

    error_notice current_user.errors.full_messages
  end

  private

  def process_order
    service = CreateOrderService.call(current_user, params[:user][:bonus])
    return handle_success_notice if service[:success]

    # redirect_to root_path, alert: service[:error]
    render turbo_stream: [
      send_notice(service[:error], 'danger'),
      turbo_stream.append(:modal, '<script>window.location.href = "/";</script>'.html_safe)
    ], status: :unprocessable_entity
  end

  def handle_success_notice
    render turbo_stream: [
      success_notice(t('.success')),
      turbo_stream.append(:modal, '<script>window.location.href = "/";</script>'.html_safe),
      turbo_stream.append(:modal, '<script>closeMiniApp();</script>'.html_safe)
    ]
  end

  def update_user
    current_user.update(filtered_params)
  end
end
