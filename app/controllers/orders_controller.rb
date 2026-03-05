class OrdersController < ApplicationController
  def index
    @orders = current_user.orders.order(updated_at: :desc)
    # TODO: add pagination
  end

  def show
    @order = current_user.orders.includes(order_items: { product: :image_attachment }).find(params[:id])
    render turbo_stream: turbo_stream.update('modal-block', partial: '/orders/show', locals: { order: @order })
  end

  def create
    return error_notice(t('.agreement')) if params[:user][:agreement] != '1'
    return error_notice(t('.required_fields')) unless required_fields_filled?

    process_order
  end

  private

  def process_order
    if current_user.update(filtered_params)
      result = CreateOrderService.call(current_user, params[:user][:bonus])
      result[:error] ? error_notice(result[:error]) : handle_success_notice
    else
      error_notice current_user.errors.full_messages
    end
  end

  def handle_success_notice
    render turbo_stream: [
      success_notice(t('.success')),
      turbo_stream.append(:modal, '<script>window.location.href = "/thanks.html";</script>'.html_safe),
      turbo_stream.append(:modal, '<script>closeMiniApp();</script>'.html_safe)
    ]
  end
end
