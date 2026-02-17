class Review < ApplicationRecord
  SHIPPED = 4
  PHOTO_LIMIT_SIZE = 10
  THANKS_MSG = [
    'Спасибо за ваш отзыв! 🙏',
    'Ваше мнение очень важно для нас! 💙',
    'Благодарим за обратную связь! ✨',
    'Спасибо за тёплые слова! 🤗',
    'Мы ценим ваше мнение! 🌟',
    'Спасибо, что нашли время поделиться впечатлениями! 💫',
    'Ваш отзыв вдохновляет нас становиться лучше! 🚀',
    'Большое спасибо за вашу оценку! ❤️',
    'Рады, что вам понравилось! 😊',
    'Спасибо за доверие и обратную связь! 🤝'
  ].freeze

  belongs_to :user
  belongs_to :product
  has_many_attached :photos, dependent: :purge do |attachable|
    attachable.variant :big, resize_to_limit: [1920, 1080], format: :webp
    attachable.variant :thumb, resize_to_limit: [80, 80], format: :webp
  end

  validates :content, presence: true, length: { maximum: 1000 }
  validates :rating, presence: true, inclusion: { in: 1..5, message: I18n.t('errors.messages.rating_range') }
  validates :user, uniqueness: { scope: :product, message: I18n.t('errors.messages.user_already_reviewed') }
  validate :user_must_have_purchased_product
  validate :acceptable_photos

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }

  after_commit :clear_reviews_cache, on: %i[create update destroy]
  after_commit :send_thanks_msg, on: :update, if: -> { previous_changes['approved'] == [false, true] }

  def approve!
    update!(approved: true)
  end

  def reject!
    update!(approved: false)
  end

  def self.count_all_reviews
    Rails.cache.fetch(:all_reviews, expires_in: 6.hours) do
      where(approved: false).size
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id rating created_at approved user_id product_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def attach_photos(new_photos, notify: false)
    clean_photos = Array(new_photos).compact_blank
    photos.attach(clean_photos) if clean_photos.present?

    if photos.attached? && Rails.env.production?
      blob_ids = photos.last(clean_photos.size).pluck(:blob_id)
      GenerateImageVariantsJob.perform_later(blob_ids)
    end

    send_telegram_notification if notify
  end

  private

  def send_telegram_notification
    msg = "🎉 Новый отзыв №#{id}\n\n👤: #{user.user_name}\n💊: #{product.name}"
    msg += "\n⭐: #{('★' * rating) + ('☆' * (5 - rating))}"
    msg += "\n📷: Есть фото" if photos.attached?
    msg += "\n\n#{content}"
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids), markup: 'review')
  end

  def user_must_have_purchased_product
    return if user.orders.joins(:order_items).exists?(status: SHIPPED, order_items: { product_id: product_id })

    errors.add(:product, 'Вы не можете оставить отзыв на товар, который не покупали.')
  end

  def acceptable_photos
    return unless photos.attached?

    validate_photos_count
    photos.each do |photo|
      validate_photo_size(photo)
      validate_photo_type(photo)
    end
  end

  def validate_photos_count
    errors.add(:photos, 'можно загрузить не более 4 изображений') if photos.count > 4
  end

  def validate_photo_size(photo)
    return if photo.byte_size <= PHOTO_LIMIT_SIZE.megabytes

    errors.add(:photos, "'#{photo.filename}' должна быть меньше #{PHOTO_LIMIT_SIZE} МБ")
  end

  def validate_photo_type(photo)
    acceptable_types = %w[image/jpeg image/png image/webp image/heic image/heif]
    return if acceptable_types.include?(photo.content_type)

    errors.add(:photos, "'#{photo.filename}' должна быть в формате JPEG, PNG, WEBP или HEIC")
  end

  def clear_reviews_cache
    Rails.cache.delete_multi(%i[all_reviews])
  end

  def send_thanks_msg
    msg    = "Ваш отзыв на товар #{product.name} опубликован!\n#{THANKS_MSG.sample}"
    markup = { markup: { markup: 'to_catalog' } }
    user.messages.create(text: msg, is_incoming: false, data: markup)
  end
end
