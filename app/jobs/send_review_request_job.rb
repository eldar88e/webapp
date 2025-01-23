class SendReviewRequestJob < ApplicationJob
  queue_as :default

  def perform(**args)
    product = Product.find_by(id: args[:product_id])
    user    = User.find_by(id: args[:user_id])

    if product.nil? || user.nil?
      Rails.logger.error "SendReviewRequestJob: Product or User not found (Product ID: #{args[:product_id]}, User ID: #{args[:user_id]})"
      return
    end

    review_url = "products_#{product.id}_reviews_new"

    TelegramService.call(
      "Вы недавно покупали #{product.name}, пожалуйста оставте отзыв.",
      user.tg_id,
      markup_custom: 'Оставить отзыв',
      markup_url: "https://yourapp.com/#{review_url}"
    )

    Rails.logger.info "Review request sent to user #{user.id} for product #{product.id}"
  end
end
