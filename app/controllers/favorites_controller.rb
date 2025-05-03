class FavoritesController < ApplicationController
  before_action :set_product, only: %i[create destroy]
  before_action :favorite_products, only: :index

  def index; end

  def create
    current_user.favorites.create(product: @product)
    render turbo_stream: [
      turbo_stream.replace("favorite-btn-#{@product.id}", partial: '/favorites/button', locals: { product: @product }),
      success_notice('Добавлено в избранное.')
    ]
  end

  def destroy
    current_user.favorites.find_by(product: @product)&.destroy
    stream = [turbo_stream.replace("favorite-btn-#{@product.id}", partial: '/favorites/button', locals: { product: @product }),
              success_notice('Удалено из избранного.')]
    if request.url.include?('/products/')
      favorite_products
      stream << turbo_stream.replace(:favorites, partial: '/favorites/favorites')
    end
    render turbo_stream: stream
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def favorite_products
    @pagy, @products = pagy(current_user.favorite_products.includes(:image_attachment), limit: 10)
  end
end
