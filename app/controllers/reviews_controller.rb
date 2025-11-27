class ReviewsController < ApplicationController
  include Pagy::Method

  before_action :set_product
  before_action :detect_device, only: :new

  def index
    @product = Product.find(params[:product_id])
    @reviews = @product.reviews.includes(:user, :photos_attachments).approved.order(created_at: :desc)
    @pagy, @reviews = pagy(@reviews, limit: 10)
    render turbo_stream: [
      turbo_stream.replace(:next_reviews, partial: '/reviews/reviews')
    ]
  end

  def new
    @review = current_user.reviews.new(product: @product)
    return unless turbo_frame_request?

    render turbo_stream: [
      turbo_stream.update(:new_review, partial: '/reviews/form', locals: { method: :post })
    ]
  end

  def create
    @review = @product.reviews.new(review_params.except(:photos).merge(user: current_user))
    if @review.save
      @review.attach_photos(review_params[:photos], notify: true)
      render turbo_stream: render_create
    else
      error_notice @review.errors.full_messages
    end
  end

  private

  def render_create
    [
      turbo_stream.update(:new_review, 'Ваш отзыв на модерации.'),
      turbo_stream.update(:new_review_page, partial: '/reviews/notice'),
      success_notice('Отзыв успешно добавлен.')
    ]
  end

  def set_product
    @product = Product.find(params[:product_id])
  end

  def review_params
    params.require(:review).permit(:content, :rating, photos: [])
  end

  def detect_device
    user_agent = request.user_agent.to_s.downcase
    @is_android = user_agent.include?('android') && user_agent.include?('mobile')
  end
end
