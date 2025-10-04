class SendReviewRequestJob < ApplicationJob
  queue_as :default
  BTN_TITLE = '💬 Оставить отзыв'.freeze

  def perform(**args)
    product = Product.find(args[:product_id])
    user    = User.find(args[:user_id])
    order   = user.orders.find_by(id: args[:order_id])
    return if order&.status != 'shipped' || user.reviews.exists?(product_id: product.id)

    # return send_review_request_mirena(user) if ENV.fetch('HOST', '').include?('mirena')

    message = build_tg_message(product)
    send_review_request(user, message)
  end

  private

  def build_tg_message(product)
    text   = I18n.t('tg_msg.review', product: product.name)
    markup = { markup_url: "products_#{product.id}_reviews_new", markup_text: BTN_TITLE }
    Tg::MessageService.build_tg_message(product, text, markup)
  end

  def send_review_request(user, message)
    msg = user.messages.create(**message)
    Tg::MessageService.update_file_id(msg)
  end

  # def send_review_request_mirena(user)
  #   text = I18n.t('tg_msg.review_mirena')
  #   url  = Setting.fetch_value(:reviews_group)
  #   data = { markup: { markup_ext_url: url, markup_ext_text: BTN_TITLE } }
  #   user.messages.create(text: text, is_incoming: false, data: data)
  # end
end
