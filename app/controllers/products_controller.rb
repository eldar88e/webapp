class ProductsController < ApplicationController
  before_action :available_products, only: [:index]

  def index
    @pagy, @products = pagy(@products, limit: 5)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(:pagination, partial: '/products/pagination'),
          turbo_stream.append(:products, partial: '/products/products')
        ]
      end
    end
  end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.includes(:user, :photos_attachments).approved.order(created_at: :desc)
  end
end
