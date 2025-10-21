class Product < ApplicationRecord
  include AttachableImages

  IS_NOT_MIRENA      = ENV.fetch('HOST', '').exclude?('mirena')
  MIN_STOCK_QUANTITY = 15

  has_ancestry
  has_one_attached :image, dependent: :purge
  has_many :reviews, dependent: :destroy
  has_many :product_subscriptions, dependent: :destroy
  has_many :subscribers, through: :product_subscriptions, source: :user
  has_many :order_items, dependent: :restrict_with_error
  has_many :cart_items, dependent: :restrict_with_error
  has_many :favorites, dependent: :destroy
  has_many :favored_by_users, through: :favorites, source: :user

  before_validation :normalize_ancestry

  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true
  validate :acceptable_image, if: -> { attachment_changes['image'].present? }

  scope :available, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :children_only, -> { where.not(ancestry: nil) }

  before_update :notify_if_low_stock, if: :stock_quantity_changed?
  after_commit :clear_available_categories_cache, on: %i[create update destroy]
  after_commit :notify_subscribers_if_restocked, if: :saved_change_to_stock_quantity?
  after_commit :export_product_google, on: %i[update create], if: -> { should_export_product_google? }
  after_commit :webhook_to_mirena, on: :update, if: lambda {
    IS_NOT_MIRENA && saved_change_to_stock_quantity? && id == Setting.fetch_value(:mirena_id).to_i
  }

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

    errors.add(:image, 'должно быть меньше 1 МБ') if image.byte_size > 1.megabyte

    acceptable_types = %w[image/jpeg image/png image/webp]
    return if acceptable_types.include?(image.content_type)

    errors.add(:image, 'должно быть JPEG или PNG или WEBP')
  end

  def subscribed?(user)
    product_subscriptions.exists?(user: user)
  end

  def self.available_categories(root_id)
    Rails.cache.fetch("available_categories_#{root_id}", expires_in: 30.minutes) do
      exists?(root_id) ? find(root_id).children.available.order(:created_at) : []
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name stock_quantity price ancestry favorites_count]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def attach_image(new_image)
    attach_file(image, new_image)
  end

  private

  def should_export_product_google?
    return false unless IS_NOT_MIRENA

    previous_changes.key?('id') || saved_change_to_stock_quantity?
  end

  def webhook_to_mirena
    UpdateProductStockJob.perform_later(id, Setting.fetch_value(:mirena_webhook_url))
  end

  def notify_subscribers_if_restocked
    previous_stock = saved_changes[:stock_quantity]&.first || stock_quantity_before_last_save
    return unless previous_stock.zero? && stock_quantity.positive?

    SubscribersNoticeJob.perform_later(id)
  end

  def notify_if_low_stock
    if stock_quantity < MIN_STOCK_QUANTITY && stock_quantity_was >= MIN_STOCK_QUANTITY
      msg = "⚠️ Внимание! Осталось всего #{stock_quantity} единиц товара '#{name}'!"
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
    end
    return unless stock_quantity < 10

    msg = "‼️Осталось #{stock_quantity}шт. #{name} на складе!"
    Rails.logger.info msg
    TelegramJob.perform_later(msg: msg)
  end

  def clear_available_categories_cache
    Rails.cache.delete("available_categories_#{Setting.fetch_value(:root_product_id)}")
  end

  def normalize_ancestry
    self.ancestry = ancestry.presence
  end

  def export_product_google
    GoogleSheetsExporterJob.perform_later(ids: id, model: :product)
  end
end
