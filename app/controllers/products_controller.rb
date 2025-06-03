class ProductsController < ApplicationController
  skip_before_action :check_authenticate_user!, only: :index
  before_action :set_btn_link, :login, only: :index

  def index
    redirect_to "/products/#{Setting.fetch_value(:mirena_id)}" if ENV.fetch('HOST').include?('mirena')

    @products = params[:q].nil? ? available_products : @q_products.result
    # @pagy, @products = pagy(@products, limit: 10)
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [turbo_stream.append(:products, partial: '/products/products')]
        # turbo_stream.replace(:pagination, partial: '/products/pagination')
      end
    end
  end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.includes(:user, :photos_attachments).approved.order(created_at: :desc)
    # TODO:  Добавить пагинацию для отзывов
  end

  private

  def login
    return redirect_to login_path(btn_link: @btn_link) unless current_user
    return redirect_to '/error-register' if current_user.started.blank? || current_user.is_blocked.present?

    redirect_to "/#{@btn_link}" if @btn_link.present?
  end

  def set_btn_link
    return if params['tgWebAppStartParam'].blank? || params['tgWebAppStartParam'].exclude?('url=')

    @btn_link = params['tgWebAppStartParam'].sub('url=', '').tr('_', '/') # TODO: возможно "_" убрать из url
  end
end
