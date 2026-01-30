module Admin
  class ProductStatisticsController < Admin::ApplicationController
    before_action :set_date_range, :load_product_statistics

    def index
      @purchase_items = Purchase.find_by(status: :initialized)&.purchase_items&.pluck(:product_id) || []

      respond_to do |format|
        format.html
        format.json { render json: @product_statistics }
      end
    end

    def xlsx
      package = StatisticExcelService.call(@product_statistics)

      filename = "product_statistics_#{@start_date.to_date}_#{@end_date.to_date}.xlsx"
      send_data package.to_stream.read,
                filename: filename,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    end

    private

    def load_product_statistics
      root_products = Product.available.where(ancestry: nil)
      ids = root_products.map { |item| item.descendants.ids }.flatten
      products = Product.available.includes(:image_attachment)
                        .where(id: ids, price: 0..)
                        .order(:name)
      @product_statistics = StatisticsService.call(products, @start_date, @end_date)
    end

    def set_date_range
      @start_date = params[:start_date].present? ? params[:start_date].to_date : 6.months.ago
      @end_date = params[:end_date].present? ? params[:end_date].to_date : Time.current
    end
  end
end
