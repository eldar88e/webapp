class SendReviewRequestJob < ApplicationJob
  queue_as :default

  def perform(**args)
    product = Product.find(args[:product_id])
    user    = User.find(args[:user_id])
    order   = Order.find(args[:order_id])
    return if order.status != 'shipped'

    msg = I18n.t('tg_msg.review', product: product.name)
    url = "products_#{product.id}_reviews_new"
    TelegramService.call(msg, user.tg_id, markup_text: 'Оставить отзыв', markup_url: url)
    Rails.logger.info "Review request sent to user #{user.id} for product #{product.id}"
  end
end
