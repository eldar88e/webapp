module Payment
  class AttachmentJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order  = Order.find(order_id)
      result = Payment::ApiService.order_check_down(order.payment_transaction, helpers.storage_path(order.attachment))
      return if result&.dig('response') == 'success'

      order.attachment.purge
      msg    = "‼️ Failed to attach check for Order ##{order.id}.\nResponse:\n#{result}"
      markup = { markup_url: 'admin/orders', markup_text: '📋 Перейти к заказам' }
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids), **markup)
    end
  end
end
