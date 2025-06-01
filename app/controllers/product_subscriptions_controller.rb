class ProductSubscriptionsController < ApplicationController
  before_action :set_product, only: %i[create destroy]
  before_action :product_subscriptions, only: :index

  def index; end

  def create
    subscription = current_user.product_subscriptions.new(product: @product)
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
    current_user.product_subscriptions.find_by(product: @product)&.destroy
    stream = [turbo_stream.replace("subscribe_#{@product.id}", partial: '/product_subscriptions/btn',
                                                               locals: { product: @product }),
              success_notice('Вы отписались от уведомлений.')]
    update_page(stream)
    render turbo_stream: stream
  end

  private

  def update_page(stream)
    return unless request.referer&.include?('/product_subscriptions')

    product_subscriptions
    stream << turbo_stream.replace(:product_subscriptions, partial: '/product_subscriptions/product_subscriptions')
  end

  def set_product
    @product = Product.find(params[:product_id])
  end

  def product_subscriptions
    @pagy, @products = pagy(current_user.subscriptions_products.includes(:image_attachment), limit: 10)
  end
end
