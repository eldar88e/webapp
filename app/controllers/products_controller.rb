class ProductsController < ApplicationController
  before_action :available_products, only: [:index]

  def index
    redirect_to carts_path if params[:start] == 'cart'
  end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.includes(:user, :photos_attachments).approved
  end
end
