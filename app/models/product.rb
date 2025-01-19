class Product < ApplicationRecord
  has_ancestry
  has_one_attached :image, dependent: :purge
  has_many :reviews, dependent: :destroy

  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true
  validate :acceptable_image

  scope :available, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :children_only, -> { where.not(ancestry: nil) }

  def destroy
    transaction do
      descendants.each { |i| i.update(deleted_at: Time.current) }
      update(deleted_at: Time.current)
    end
  end

  def restore
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  def acceptable_image
    return unless image.attached?

    if image.byte_size > 1.megabyte
      errors.add(:image, 'должно быть меньше 1 МБ')
    end

    acceptable_types = %w[image/jpeg image/png image/webp]
    unless acceptable_types.include?(image.content_type)
      errors.add(:image, 'должно быть JPEG или PNG или WEBP')
    end
  end
end
