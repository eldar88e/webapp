class UpdaterProductStockService
  class << self
    def process_product(params)
      product = Product.find_by(name: params[:product_name])
      return { error: "Product #{product.id} not found" } if product.nil?

      if params[:stock_quantity] # for mirena
        product.update!(stock_quantity: params[:stock_quantity].to_i)
        { success: "Product #{product.id} Stock quantity updated" }
      elsif params[:quantity_decrement] # for main stock
        process_quantity_decrement(product, params)
      end
    rescue StandardError => e
      { error: "#{e.class}: #{e.message}" }
    end

    private

    def process_quantity_decrement(product, params)
      return main_stock_not_available_log(product) if insufficient_stock?(product, params[:quantity_decrement].to_i)

      new_quantity = [product.stock_quantity - params[:quantity_decrement].to_i, 0].max
      product.update!(stock_quantity: new_quantity)
      { success: "Product #{product.id} Stock quantity decremented" }
    end

    def insufficient_stock?(product, required_quantity)
      product.stock_quantity < required_quantity || product.stock_quantity.zero?
    end

    def main_stock_not_available_log(product)
      msg = "Product #{product.id} Stock quantity must be greater than or equal to 1 or order item quantity!"
      Rails.logger.error(msg)
      TelegramJob(msg: msg, id: Setting.fetch_value(:admin_ids))
      { error: msg }
    end
  end
end
