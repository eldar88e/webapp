class BankCard < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  validates :fio, presence: true
  validates :number, presence: true

  scope :active, -> { where(active: true) }

  after_commit :clear_cache

  def bank_details
    "#{name} — #{fio} — `#{number}`"
  end

  def self.cached_available
    Rails.cache.fetch(:available_bank_cards) { active.ids }
  end

  def self.sample_bank_card
    cached_available.sample
  end

  private

  def clear_cache
    Rails.cache.delete(:available_bank_cards)
  end
end
