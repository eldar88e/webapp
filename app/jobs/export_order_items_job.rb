class ExportOrderItemsJob < ApplicationJob
  queue_as :default

  def perform(order_ids, del = nil)
    Order.where(id: order_ids).find_each do |order|
      GoogleSheetsService.new(order).send(del ? :delete_order_items_from_sheets : :export_order_items_to_sheets)
      sleep rand(3..7)
    end
  end
end
