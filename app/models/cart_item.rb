class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  before_validation :check_product_stock
  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :product_id, uniqueness: { scope: :cart_id, message: I18n.t('errors.messages.already_in_cart') }
  # after_commit :add_or_remove_delivery_item, on: %i[create update destroy]

  private

  def check_product_stock
    return if quantity.nil?

    return unless quantity > product.stock_quantity

    errors.add(:quantity, 'товара недостаточно на складе')
    throw(:abort)
  end

  # TODO: удалить
  def add_or_remove_delivery_item
    delivery_id              = Setting.fetch_value(:delivery_id)
    non_delivery_items_count = cart.cart_items.where.not(product_id: delivery_id).sum(:quantity)
    if non_delivery_items_count == 1
      cart.cart_items.find_or_create_by(product_id: delivery_id)
    else
      cart.cart_items.find_by(product_id: delivery_id)&.destroy
    end
  end
end
