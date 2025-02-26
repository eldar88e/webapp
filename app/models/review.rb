class Review < ApplicationRecord
  SHIPPED = 4

  belongs_to :user
  belongs_to :product
  has_many_attached :photos, dependent: :purge do |attachable|
    attachable.variant :big, resize_to_limit: [1920, 1080], format: :webp
    attachable.variant :thumb, resize_to_limit: [80, 80], format: :webp
  end

  validates :content, presence: true, length: { maximum: 1000 }
  validates :rating, presence: true, inclusion: { in: 1..5, message: I18n.t('errors.messages.rating_range') }
  validate :user_must_have_purchased_product
  validate :user_cannot_review_twice, on: :create
  validate :acceptable_photos

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }

  after_commit :process_photos, on: :create
  after_create_commit :send_telegram_notification

  def approve!
    update!(approved: true)
  end

  def reject!
    update!(approved: false)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id rating created_at approved user_id product_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  private

  def process_photos
    ProcessReviewPhotosJob.perform_later(self) # TODO: Cкорее всего такую структуру sidekiq не поддерживает
  end

  def send_telegram_notification
    TelegramJob.perform_later(
      msg: "Новый отзыв\nот: #{user.user_name}\nтовар: #{product.name}\nрейтинг: #{star_rating(rating)}\n\n#{content}",
      id: Setting.fetch_value(:admin_ids)
    )
  end

  def star_rating(rating)
    ('★' * rating) + ('☆' * (5 - rating))
  end

  def user_must_have_purchased_product
    return if user.orders.joins(:order_items).exists?(status: SHIPPED, order_items: { product_id: product_id })

    errors.add(:product, 'Вы не можете оставить отзыв на товар, который не покупали.')
  end

  def user_cannot_review_twice
    return unless Review.exists?(user_id: user_id, product_id: product_id)

    errors.add(:product, 'Вы уже оставили отзыв на этот товар.')
  end

  def acceptable_photos
    return unless photos.attached?

    errors.add(:photos, 'можно загрузить не более 4 изображений') if photos.count > 4

    photos.each do |photo|
      errors.add(:photos, "'#{photo.filename}' должна быть меньше 5 МБ") if photo.byte_size > 5.megabytes

      acceptable_types = %w[image/jpeg image/png image/webp image/heic image/heif]
      unless acceptable_types.include?(photo.content_type)
        errors.add(:photos, "'#{photo.filename}' должна быть в формате JPEG, PNG, WEBP или HEIC")
      end
    end
  end
end
