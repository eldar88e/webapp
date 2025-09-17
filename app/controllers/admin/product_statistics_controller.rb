module Admin
  class ProductStatisticsController < Admin::ApplicationController
    def index
      products = Product.available.includes(:image_attachment).order(created_at: :desc)
      @product_statistics = StatisticsService.call(products)
    end
  end
end
