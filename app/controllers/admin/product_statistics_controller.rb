module Admin
  class ProductStatisticsController < Admin::ApplicationController
    before_action :set_date_range

    def index
      root_products = Product.available.where(ancestry: nil)
      ids = root_products.map { |item| item.descendants.ids }.flatten
      products = Product.available.includes(:image_attachment)
                        .where(id: ids, price: 0..)
                        .order(:name)
      @product_statistics = StatisticsService.call(products, @start_date, @end_date)
    end

    private

    def set_date_range
      @start_date = params[:start_date].present? ? params[:start_date].to_date : 6.months.ago
      @end_date = params[:end_date].present? ? params[:end_date].to_date : Time.current
    end
  end
end
