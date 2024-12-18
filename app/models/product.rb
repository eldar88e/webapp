class Product < ApplicationRecord
  has_one_attached :image, dependent: :purge

  validates :stock_quantity, presence: true
  validates :name, presence: true

  scope :available, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def destroy
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
end
