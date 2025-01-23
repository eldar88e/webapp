class Review < ApplicationRecord
  SHIPPED = 4

  belongs_to :user
  belongs_to :product
  has_many_attached :photos, dependent: :purge do |attachable|
    attachable.variant :big, resize_to_limit: [1920, 1080], format: :webp
    attachable.variant :thumb, resize_to_limit: [80, 80], format: :webp
  end

  validates :content, presence: true, length: { maximum: 1000 }
  validates :rating, presence: true, inclusion: { in: 1..5, message: 'должен быть от 1 до 5' }
  validate :user_must_have_purchased_product
  validate :user_cannot_review_twice, on: :create
  validate :acceptable_photos

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }

  def approve!
    update!(approved: true)
  end

  def reject!
    update!(approved: false)
  end

  private

  def user_must_have_purchased_product
    unless user.orders.joins(:order_items).where(status: SHIPPED, order_items: { product_id: product_id }).exists?
      errors.add(:product, 'Вы не можете оставить отзыв на товар, который не покупали.')
    end
  end

  def user_cannot_review_twice
    if Review.exists?(user_id: user_id, product_id: product_id)
      errors.add(:product, 'Вы уже оставили отзыв на этот товар.')
    end
  end

  def acceptable_photos
    return unless photos.attached?

    if photos.count > 4
      errors.add(:photos, 'можно загрузить не более 4 изображений')
    end

    photos.each do |photo|
      if photo.byte_size > 5.megabyte
        errors.add(:photos, "'#{photo.filename}' должна быть меньше 5 МБ")
      end

      acceptable_types = %w[image/jpeg image/png image/webp image/heic image/heif]
      unless acceptable_types.include?(photo.content_type)
        errors.add(:photos, "'#{photo.filename}' должна быть в формате JPEG, PNG, WEBP или HEIC")
      end
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id rating created_at approved user_id product_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end
end
