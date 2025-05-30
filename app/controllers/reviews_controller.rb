class ReviewsController < ApplicationController
  before_action :set_product
  before_action :detect_device, only: :new

  def new
    @review = current_user.reviews.new(product: @product)
    return unless turbo_frame_request?

    render turbo_stream: [
      turbo_stream.update(:new_review, partial: '/reviews/form', locals: { method: :post })
    ]
  end

  def create
    @review = @product.reviews.new(review_params.merge(user: current_user))
    if @review.save
      render turbo_stream: [
        turbo_stream.update(:new_review, 'Ваш отзыв на модерации.'),
        turbo_stream.update(:new_review_page, partial: '/reviews/notice'),
        success_notice('Отзыв успешно добавлен.')
      ]
    else
      error_notice @review.errors.full_messages
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def review_params
    permitted_params = params.require(:review).permit(:content, :rating, photos: [])
    photos_param     = params.require(:review)[:photos]
    if photos_param.present?
      permitted_params[:photos] = Array.wrap(photos_param)
    else
      permitted_params.delete(:photos)
    end
    permitted_params
  end

  def detect_device
    user_agent = request.user_agent.to_s.downcase
    @is_android = user_agent.include?('android') && user_agent.include?('mobile')
  end
end
