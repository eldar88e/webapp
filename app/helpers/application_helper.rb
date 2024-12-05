module ApplicationHelper
  def cart_items_total
    current_user.cart.cart_items.sum(&:quantity)
  end

  def quantity_curt_item(id)
    current_user.cart.cart_items.find_by(product_id: id)&.quantity.to_i
  end
end
