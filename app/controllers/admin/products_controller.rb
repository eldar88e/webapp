module Admin
  class ProductsController < Admin::ApplicationController
    before_action :set_product, only: %i[edit update destroy]

    def index
      @q_products = Product.includes(:image_attachment).order(:created_at).ransack(params[:q])

      root_product_id = Setting.fetch_value(:root_product_id)
      if root_product_id
        form_products(root_product_id)
      else
        @result = @q_products.result
      end

      @pagy, @products = pagy(@result, items: 20)
    end

    def new
      @product = Product.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить товар'),
        turbo_stream.update(:modal_body, partial: '/admin/products/new')
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать товар'),
        turbo_stream.update(:modal_body, partial: '/admin/products/edit')
      ]
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: t('controller.products.create')
      else
        error_notice(@product.errors.full_messages, :unprocessable_entity)
      end
    end

    def update
      if params[:restore]
        @product.restore
        render turbo_stream: render_turbo_stream('update_restore')
      elsif @product.update(product_params)
        render turbo_stream: render_turbo_stream('update')
      else
        error_notice(@product.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @product.destroy
      render turbo_stream: render_turbo_stream('destroy')
    end

    private

    def form_products(root_product_id)
      session[:filter] = params[:filter].presence || session[:filter].presence || 'descendants'
      root_product = Product.find(root_product_id)
      @result = if root_product && session[:filter] == 'descendants'
                  @q_products.result.where(id: root_product.descendants.ids).where.not(id: root_product.children.ids)
                elsif root_product && session[:filter] == 'children'
                  @q_products.result.where(id: root_product.children.ids)
                else
                  @q_products.result
                end
    end

    def render_turbo_stream(notice)
      [
        success_notice(t("controller.products.#{notice}")),
        turbo_stream.replace(@product, partial: '/admin/products/product', locals: { product: @product })
      ]
    end

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :price, :stock_quantity, :image, :ancestry, :brand,
                                      :weight, :dosage_form, :package_quantity, :main_ingredient)
    end
  end
end
