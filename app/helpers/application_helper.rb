module ApplicationHelper
  def cart_items_total
    current_user.cart.cart_items.sum(&:quantity)
  end

  def quantity_curt_item(id)
    current_user.cart.cart_items.find_by(product_id: id)&.quantity.to_i
  end

  def storage_path(attach, variant = nil)
    blob = variant ? attach : attach.blob

    case attach.blob.service_name
    when 'minio' then minio_storage_path(blob)
    when 'local' then local_storage_path(blob)
    else url_for(attach)
    end
  rescue StandardError => e
    Rails.logger.error "Error getting file path: #{e.message}"
    nil
  end

  def available_categories
    Product.available_categories(Setting.fetch_value(:root_product_id))
  end

  def minio_storage_path(blob)
    "#{ENV.fetch('MINIO_HOST')}/#{ENV.fetch('MINIO_BUCKET')}/#{blob.key}"
  end

  def local_storage_path(blob)
    return url_for(blob) unless Rails.env.production?

    "/storage/#{blob.key[0..1]}/#{blob.key[2..3]}/#{blob.key}.#{blob.content_type.split('/').last}"
  end
end
