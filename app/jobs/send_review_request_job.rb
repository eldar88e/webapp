class SendReviewRequestJob < ApplicationJob
  queue_as :default

  def perform(**args)
    product = Product.find(args[:product_id])
    user    = User.find(args[:user_id])
    order   = user.orders.find_by(id: args[:order_id])
    return if order&.status != 'shipped'

    send_review_request(user, product)
  end

  private

  def send_review_request(user, product)
    msg    = I18n.t('tg_msg.review', product: product.name)
    url    = "products_#{product.id}_reviews_new"
    msg_id = TelegramService.call(msg, user.tg_id, markup_text: 'Оставить отзыв', markup_url: url)
    if msg_id.instance_of?(Integer)
      Rails.logger.info "Review request sent to user #{user.id} for product #{product.id}"
    else
      limit_user_privileges(msg_id, user)
    end
  end
end
