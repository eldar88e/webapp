module Admin
  class ProductsController < Admin::ApplicationController
    before_action :set_product, only: %i[edit update destroy]

    def index
      @q_products = Product.includes(:image_attachment).order(:created_at).ransack(params[:q])

      root_product_id = Setting.fetch_value(:root_product_id)
      if root_product_id
        session[:filter] = params[:filter].presence || session[:filter].presence || 'descendants'
        case session[:filter]
        when 'descendants'
          root_product = Product.find(root_product_id)
          @result      = @q_products.result.where(id: root_product.descendants.ids)
                                    .where.not(id: root_product.children.ids)
        when 'children'
          root_product = Product.find(root_product_id)
          @result      = @q_products.result.where(id: root_product.children.ids)
        when 'services'
          delivery_id = Setting.fetch_value(:delivery_id)
          @result     = delivery_id ? @q_products.result.where(id: delivery_id) : @q_products.result
        else
          @result = @q_products.result
        end
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
        redirect_to admin_products_path, notice: t('controller.products.update_restore')
      elsif @product.update(product_params)
        render turbo_stream: [
          success_notice(t('controller.products.update')),
          turbo_stream.replace(@product, partial: '/admin/products/product', locals: { product: @product })
        ]
      else
        error_notice(@product.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, status: :see_other, notice: t('controller.products.destroy')
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :price, :stock_quantity, :image, :ancestry, :brand,
                                      :weight, :dosage_form, :package_quantity, :main_ingredient)
    end
  end
end
