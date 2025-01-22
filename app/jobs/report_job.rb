class ReportJob < ApplicationJob
  queue_as :default

  def perform(**args)
    order = Order.find(args[:order_id])
    return if order.status == 'initialized'

    method_name = "on_#{order.status}".to_sym
    ReportService.send(method_name, order)
  end
end
