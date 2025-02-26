require 'faraday'

class UpdateProductStockJob < ApplicationJob
  queue_as :default

  def perform(product_id, webhook_url, quantity_decrement = nil)
    return Rails.logger.error "Empty webhook url for Product ##{product_id}" if webhook_url.blank?

    product = Product.find_by(id: product_id)
    return Rails.logger.error("#{self.class} | Product #{product_id} not found!") unless product

    payload = form_payload(product, quantity_decrement)
    post_request(product_id, payload, webhook_url)
  rescue StandardError => e
    msg = "Failed to send webhook for Product ##{product_id}: #{e.message}"
    Rails.logger.error msg
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
  end

  private

  def post_request(product_id, payload, webhook_url)
    response = Faraday.post(webhook_url, payload.to_json, 'Content-Type' => 'application/json')
    return Rails.logger.info JSON.parse(response.body)['success'] if response.success?

    Rails.logger.error "Sending webhook for Product ##{product_id}: #{response.status} - #{response.body}"
  end

  def form_payload(product, quantity_decrement)
    payload = { product_name: product.name, updated_at: product.updated_at }
    if quantity_decrement
      payload[:quantity_decrement] = quantity_decrement
    else
      payload[:stock_quantity] = product.stock_quantity
    end
    payload
  end
end
