class CartsController < ApplicationController
  before_action :available_products

  def index
    @cart_items = current_user.cart.cart_items.includes(:product).order(:created_at)
  end
end
