module ApplicationHelper
  def cart_items_total
    current_user.cart.cart_items.sum(&:quantity)
  end

  def quantity_curt_item(id)
    current_user.cart.cart_items.find_by(product_id: id)&.quantity.to_i
  end

  def storage_path(attach)
    if attach.blob.service_name == 'minio'
      "#{ENV.fetch('MINIO_HOST')}/#{ENV.fetch('MINIO_BUCKET')}/#{attach.blob.key}"
    else
      url_for attach
    end
  end
end
