class ProductsController < ApplicationController
  def index
    return redirect_to carts_path if params[:start] == 'cart'

    @products = Product.includes(:image_attachment).order(updated_at: :desc)
  end
end
