class ReviewsController < ApplicationController
  before_action :set_product

  def new
    @review = current_user.reviews.new
    @review.product = @product
    render turbo_stream: [
      turbo_stream.update(:new_review, partial: '/reviews/form', locals: { review: @review, method: :post })
    ]
  end

  def create
    @review = @product.reviews.new(review_params)
    @review.user = current_user

    if @review.save
      render turbo_stream: [
        turbo_stream.update(:new_review, ''),
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
    params.require(:review).permit(:content, :rating, photos: [])
  end
end
