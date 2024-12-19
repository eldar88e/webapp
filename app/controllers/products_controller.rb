class ProductsController < ApplicationController
  before_action :available_products

  def index
    redirect_to carts_path if params[:start] == 'cart'
  end
end
