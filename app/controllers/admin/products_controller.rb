module Admin
  class ProductsController < Admin::ApplicationController
    before_action :set_product, only: %i[edit update destroy]

    def index
      @q_products = Product.includes(:image_attachment).order(:created_at).ransack(params[:q])
      @pagy, @products = pagy(@q_products.result, items: 20)
    end

    def new
      @product = Product.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить товар'),
        turbo_stream.update(:modal_body, partial: '/admin/products/new')
      ]
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_products_path, notice: 'Товар был успешно добавлен.'
      else
        error_notice(@product.errors.full_messages, :unprocessable_entity)
      end
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать товар'),
        turbo_stream.update(:modal_body, partial: '/admin/products/edit')
      ]
    end

    def update
      if params[:restore]
        @product.restore
        redirect_to admin_products_path, notice: 'Товар был успешно восстановлен.'
      elsif @product.update(product_params)
        render turbo_stream: [
          success_notice('Данные пользователя успешно обновлены.'),
          turbo_stream.replace(@product, partial: '/admin/products/product', locals: { product: @product })
        ]
      else
        error_notice(@product.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, status: :see_other, notice: 'Товар был успешно удален.'
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :price, :stock_quantity, :image, :ancestry)
    end
  end
end
