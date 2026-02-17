module Admin
  class ProductsController < Admin::ApplicationController
    before_action :set_product, only: %i[edit update destroy]
    before_action :set_products_scope, only: :index

    def index
      @q_products       = @products_scope.ransack(params[:q])
      @q_products.sorts = 'created_at desc' if @q_products.sorts.empty?
      @pagy, @products  = pagy @q_products.result
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
      @product = Product.new(product_params.except(:image))
      if @product.save
        @product.attach_image(product_params[:image])
        redirect_to admin_products_path, notice: t('controller.products.create')
      else
        error_notice @product.errors.full_messages
      end
    end

    def update
      if params[:restore]
        @product.restore
        render turbo_stream: render_turbo_stream('update_restore')
      elsif update_product_with_image
        render turbo_stream: render_turbo_stream('update')
      else
        error_notice @product.errors.full_messages
      end
    end

    def destroy
      @product.destroy
      render turbo_stream: render_turbo_stream('destroy')
    end

    private

    def update_product_with_image
      success = @product.update(product_params.except(:image))
      @product.attach_image(product_params[:image]) if success

      success
    end

    def set_products_scope
      @products_scope = Product.includes(:image_attachment)
      root_product    = Product.find_by(id: Setting.fetch_value(:root_product_id).to_i)
      return if root_product.blank?

      session[:filter] = params[:filter].presence || session[:filter].presence || 'descendants'
      filter_products(root_product)
    end

    def filter_products(root_product)
      case session[:filter]
      when 'descendants'
        @products_scope = @products_scope.where(id: root_product.descendants.ids)
                                         .where.not(id: root_product.children.ids)
      when 'children'
        @products_scope = @products_scope.where(id: root_product.children.ids)
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
      params.expect(product: %i[name description price stock_quantity image ancestry brand
                                weight dosage_form package_quantity main_ingredient old_price])
    end
  end
end
