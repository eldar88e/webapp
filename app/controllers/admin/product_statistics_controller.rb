module Admin
  class ProductStatisticsController < Admin::ApplicationController
    def index
      root_product = Product.find(Setting.fetch_value(:default_product_id))
      products = Product.available.includes(:image_attachment)
                        .where(id: root_product.descendants.ids)
                        .where.not(id: root_product.children.ids)
                        .order(:id)
      @product_statistics = StatisticsService.call(products)
    end
  end
end
