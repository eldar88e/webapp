class OrdersController < ApplicationController
  before_action :handle_user_info, only: [:create], if: -> { params[:page].to_i == 1 }

  def index
    @orders = current_user.orders.order(updated_at: :desc)
  end

  def show
    @order = current_user.orders.includes(order_items: { product: :image_attachment }).find(params[:id])
    render turbo_stream: [
      turbo_stream.update('modal-block', partial: '/orders/show', locals: { order: @order }),
      turbo_stream.append(:modal, '<script>openModal();</script>'.html_safe)
    ]
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

    if service[:success]
      render turbo_stream: [
        success_notice(t('.success')),
        turbo_stream.append(:modal, '<script>window.location.href = "/";</script>'.html_safe),
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
    current_user.update(filtered_params)
  end
end
