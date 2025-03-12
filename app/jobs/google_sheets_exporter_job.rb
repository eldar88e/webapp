class GoogleSheetsExporterJob < ApplicationJob
  queue_as :default

  def perform(**args)
    if args[:model] == :order
      export_orders(args[:ids], args[:del])
    elsif args[:model] == :product
      export_product(args[:ids])
    end
  end

  private

  def export_product(ids)
    Product.where(id: ids).find_each do |product|
      ExportProductService.new(product).synchronize_product
      sleep 1
    end
  end

  def export_orders(ids, del)
    Order.where(id: ids).find_each do |order|
      ExportOrderService.new(order).send(del ? :delete_order_items_from_sheets : :export_order_items_to_sheets)
      sleep 1 # Limit! 60 request per 60 sec. to google api .
    end
  end
end
