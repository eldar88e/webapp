class ProductsController < ApplicationController
  skip_before_action :check_authenticate_user!, only: :index
  before_action :login, :available_products, only: :index

  def index
    @pagy, @products = pagy(@products, limit: 5)
    respond_to do |format|
      format.html
      format.turbo_stream { product_turbo_format }
    end
  end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.includes(:user, :photos_attachments).approved.order(created_at: :desc)
    # TODO:  Добавить пагинацию для отзывов
  end

  private

  def login
    binding.pry
    return redirect_to login_path unless current_user
    return redirect_to '/error-register' if current_user.started.blank? || current_user.is_blocked.present?

    redirect_to "/#{@btn_link}" if @btn_link.present?
  end
end
