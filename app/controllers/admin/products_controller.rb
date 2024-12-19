module Admin
  class ProductsController < Admin::ApplicationController
    before_action :set_product, only: %i[edit update destroy]
    include Pagy::Backend

    def index
      @pagy, @products = pagy(Product.includes(:image_attachment).order(:created_at), items: 20)
    end

    def new
      @product = Product.new
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_products_path, notice: 'Товар был успешно добавлен.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if params[:restore]
        @product.restore
        redirect_to admin_products_path, notice: 'Товар был успешно восстановлен.'
      elsif @product.update(product_params)
        redirect_to admin_products_path, notice: 'Товар был успешно обновлен.'
      else
        render :edit, status: :unprocessable_entity
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
      params.require(:product).permit(:name, :description, :price, :stock_quantity, :image)
    end
  end
end
