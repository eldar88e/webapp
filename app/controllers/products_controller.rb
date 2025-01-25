class ProductsController < ApplicationController
  before_action :available_products, only: [:index]

  def index; end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.includes(:user, :photos_attachments).approved.order(created_at: :desc)
  end
end
