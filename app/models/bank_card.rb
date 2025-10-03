class BankCard < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  validates :fio, presence: true
  validates :number, presence: true

  scope :active, -> { where(active: true) }

  after_commit :clear_cache

  def bank_details
    "#{name} — #{fio} — `#{number}`"
  end

  def bank_details_admin
    "#{name} | #{fio} | #{number}"
  end

  def self.cached_available_ids
    Rails.cache.fetch(:available_bank_cards) { active.ids }
  end

  def self.sample_bank_card_id
    cached_available_ids.sample
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name fio active created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  private

  def clear_cache
    Rails.cache.delete(:available_bank_cards)
  end
end
