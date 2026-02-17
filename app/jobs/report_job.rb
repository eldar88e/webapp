class ReportJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 1.minute, attempts: 3

  def perform(**args)
    order = Order.find_by(id: args[:order_id])
    return if order.nil?

    method_name = :"on_#{order.status}"
    ReportService.send(method_name, order)
  end
end
