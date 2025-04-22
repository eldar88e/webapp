class SendReviewRequestJob < ApplicationJob
  queue_as :default

  def perform(**args)
    product = Product.find(args[:product_id])
    user    = User.find(args[:user_id])
    order   = user.orders.find_by(id: args[:order_id])
    return if order&.status != 'shipped'

    if ENV.fetch('HOST', '').include?('mirena')
      send_review_request_mirena(user)
    else
      send_review_request(user, product)
    end
  end

  private

  def send_review_request(user, product)
    text = I18n.t('tg_msg.review', product: product.name)
    url  = "products_#{product.id}_reviews_new"
    data = { markup: { markup_url: url, markup_text: '💬 Оставить отзыв' } }
    create_msg(user, text, data)
  end

  def send_review_request_mirena(user)
    text = I18n.t('tg_msg.review_mirena')
    url  = Setting.fetch_value(:reviews_group)
    data = { markup: { markup_ext_url: url, markup_ext_text: '💬 Оставить отзыв' } }
    create_msg(user, text, data)
  end

  def create_msg(user, text, data)
    message = { text: text, is_incoming: false, data: data }
    user.messages.create(**message)
    # Tg::FileService.update_file_id(message) если добавить img то убрать комментарий
  end
end
