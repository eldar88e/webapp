module ApplicationHelper
  def presence_email
    current_user.email.match?(/tgapp.online|example.com/) ? '' : current_user.email
  end

  def products_animation
    product_id = params[:category_id].presence || Setting.fetch_value(:default_product_id)
    Rails.cache.fetch("parent_#{product_id}") { available_products.pluck(:name) }
  end

  def cart_items_total
    cart_items.sum(&:quantity)
  end

  def quantity_curt_item(id)
    cart_items.find_by(product_id: id)&.quantity.to_i
  end

  def storage_path(attach, variant = nil)
    blob = variant ? attach : attach.blob

    case attach.blob.service_name
    when 'beget' then beget_storage_path(blob.key)
    when 'local' then local_storage_path(blob)
    else url_for(attach)
    end
  rescue StandardError => e
    Rails.logger.error "Error getting file path: #{e.message}"
    nil
  end

  def available_categories
    Rails.cache.fetch("categories_#{settings[:root_product_id]}") do
      Product.available_categories(settings[:root_product_id])
    end
  end

  def beget_storage_path(key)
    "#{ENV.fetch('BEGET_ENDPOINT')}/#{ENV.fetch('BEGET_BUCKET')}/#{key}"
  end

  def local_storage_path(blob)
    return url_for(blob) unless Rails.env.production?

    "/storage/#{blob.key[0..1]}/#{blob.key[2..3]}/#{blob.key}"
  end

  def remaining_to_next_tier
    current_tier  = current_user.account_tier
    account_tiers = AccountTier.all
    return account_tiers.first.order_threshold if current_tier.blank?
    return if current_tier == account_tiers.last

    next_tier = account_tiers.where('order_threshold > ?', current_tier.order_threshold).first
    remaining_orders = next_tier.order_threshold - current_user.order_count
    [remaining_orders, 0].max
  end

  def format_price(price, currency = '₽')
    MoneyService.price_to_s(price, currency)
  end
end
