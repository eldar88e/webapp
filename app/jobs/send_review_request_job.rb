class SendReviewRequestJob < ApplicationJob
  queue_as :default

  def perform(**args)
    product = Product.find_by(id: args[:product_id])
    user    = User.find_by(id: args[:user_id])
    order   = Order.find_by(id: args[:order_id])

    if product.nil? || user.nil? || %w[cancelled overdue refunded].include?(order&.status)
      Rails.logger.error "SendReviewRequestJob: Product or User not found or order status #{order&.status} (Product ID: #{args[:product_id]}, User ID: #{args[:user_id]})"
      return
    end

    TelegramService.call(
      I18n.t('tg_msg.review', product: product.name),
      user.tg_id,
      markup_text: 'Оставить отзыв',
      markup_url: "products_#{product.id}_reviews_new"
    )

    Rails.logger.info "Review request sent to user #{user.id} for product #{product.id}"
  end
end
