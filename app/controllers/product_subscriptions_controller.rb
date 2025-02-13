class ProductSubscriptionsController < ApplicationController
  before_action :set_product

  def create
    subscription = @product.product_subscriptions.find_or_initialize_by(user: current_user)
    return error_notice 'Не удалось подписаться на товар. Возможно, вы уже подписаны.' if subscription.persisted?

    if subscription.save
      render turbo_stream: [
        turbo_stream.replace("subscribe_#{@product.id}", partial: '/product_subscriptions/btn',
                                                         locals: { product: @product }),
        success_notice('Вы подписались на уведомления о поступлении товара.')
      ]
    else
      error_notice(subscription.errors.full_messages, :unprocessable_entity)
    end
  end

  def destroy
    subscription = current_user.product_subscriptions.find_by(product_id: params[:product_id])
    subscription&.destroy
    render turbo_stream: [
      turbo_stream.replace("subscribe_#{@product.id}", partial: '/product_subscriptions/btn',
                                                       locals: { product: @product }),
      success_notice('Вы отписались от уведомлений.')
    ]
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
