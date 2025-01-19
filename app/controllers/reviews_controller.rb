class ReviewsController < ApplicationController
  before_action :set_product

  def create
    return unless current_user.purchased_product?(@product)

    @review = @product.reviews.new(review_params)
    @review.user = current_user

    if @review.save
      render turbo_stream: success_notice('Отзыв успешно добавлен.')
    else
      error_notice 'Ошибка при добавлении отзыва.'
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def review_params
    params.require(:review).permit(:content, :rating)
  end
end
