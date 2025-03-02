module ApplicationHelper
  def cart_items_total
    current_user.cart.cart_items.sum(&:quantity)
  end

  def quantity_curt_item(id)
    current_user.cart.cart_items.find_by(product_id: id)&.quantity.to_i
  end

  def storage_path(attach, variant = nil)
    blob = variant ? attach : attach.blob
    if attach.blob.service_name == 'minio'
      "#{ENV.fetch('MINIO_HOST')}/#{ENV.fetch('MINIO_BUCKET')}/#{blob.key}"
    elsif attach.blob.service_name == 'local' && Rails.env.production? # work with NGINX
      "/storage/#{attach.blob.key[0..1]}/#{attach.blob.key[2..3]}/#{attach.blob.key}"
    else
      url_for attach
    end
  rescue StandardError => e
    Rails.logger.error "Error getting file path: #{e.message}"
    nil
  end

  def available_categories
    Product.available_categories(Setting.fetch_value(:root_product_id))
  end
end
