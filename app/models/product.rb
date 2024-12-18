class Product < ApplicationRecord
  has_one_attached :image, dependent: :purge

  validates :stock_quantity, presence: true
  validates :name, presence: true
end
