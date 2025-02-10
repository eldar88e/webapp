class Product < ApplicationRecord
  has_ancestry
  has_one_attached :image, dependent: :purge
  has_many :reviews, dependent: :destroy
  has_many :product_subscriptions, dependent: :destroy
  has_many :subscribers, through: :product_subscriptions, source: :user

  before_validation :normalize_ancestry

  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true
  validate :acceptable_image

  scope :available, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :children_only, -> { where.not(ancestry: nil) }

  before_update :notify_if_low_stock, if: :stock_quantity_changed?
  after_commit :clear_available_categories_cache, on: [:create, :update, :destroy]
  after_commit :notify_subscribers_if_restocked, if: :saved_change_to_stock_quantity?

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

  def subscribed?(user)
    product_subscriptions.exists?(user: user)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name stock_quantity price ancestry]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  private

  def notify_subscribers_if_restocked
    previous_stock = saved_changes[:stock_quantity]&.first || stock_quantity_before_last_save
    return unless previous_stock == 0 && stock_quantity > 0

    SubscribersNoticeJob.perform_later(self.id)
  end

  def notify_if_low_stock
    if stock_quantity < 15 && stock_quantity_was >= 15
      msg = "⚠️ Внимание! Осталось всего #{stock_quantity} единиц товара '#{name}'!"
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
    end
    if stock_quantity < 10
      msg = "‼️Осталось #{stock_quantity}шт. #{name} на складе!"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg)
    end
  end

  def clear_available_categories_cache
    Rails.cache.delete("available_categories_#{Setting.fetch_value(:root_product_id)}")
  end

  def normalize_ancestry
    self.ancestry = ancestry.presence
  end
end
