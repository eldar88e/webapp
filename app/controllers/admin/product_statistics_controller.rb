module Admin
  class ProductStatisticsController < Admin::ApplicationController
    def index
      root_products = Product.available.where(ancestry: nil).order(:created_at)
      ids = root_products.map { |item| item.descendants.ids }.flatten
      products = Product.available.includes(:image_attachment)
                        .where(id: ids, price: 0..)
                        .order(:name)
      @product_statistics = StatisticsService.call(products)
    end
  end
end
