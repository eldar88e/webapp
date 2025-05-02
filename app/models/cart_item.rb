class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validate :check_product_stock
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :product_id, uniqueness: { scope: :cart_id, message: I18n.t('errors.messages.already_in_cart') }

  private

  def check_product_stock
    return if quantity <= product.stock_quantity

    errors.add(:quantity, 'товара недостаточно на складе')
  end
end
