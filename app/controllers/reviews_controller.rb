class ReviewsController < ApplicationController
  before_action :set_product
  before_action :detect_device, only: :new

  def new
    @review = current_user.reviews.new
    @review.product = @product
    render turbo_stream: [
      turbo_stream.update(:new_review, partial: '/reviews/form', locals: { method: :post })
    ] if turbo_frame_request?
  end

  def create
    @review      = @product.reviews.new(review_params)
    @review.user = current_user

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
    binding.pry
    permitted_params = params.require(:review).permit(:content, :rating, photos: [])
    permitted_params[:photos] = [permitted_params[:photos]] if permitted_params[:photos].is_a?(String)
    permitted_params
  end

  def detect_device
    user_agent = request.user_agent.to_s.downcase
    @is_android = user_agent.include?('android') && user_agent.include?('mobile')
  end
end
