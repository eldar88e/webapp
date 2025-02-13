class ReportJob < ApplicationJob
  queue_as :default

  def perform(**args)
    order       = Order.find(args[:order_id])
    method_name = :"on_#{order.status}"
    ReportService.send(method_name, order)
  end
end
