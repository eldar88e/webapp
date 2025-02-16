class Setting < ApplicationRecord
  validates :variable, presence: true, uniqueness: true

  after_commit :clear_settings_cache, on: %i[create update destroy]

  def self.all_cached
    Rails.cache.fetch(:settings, expires_in: 6.hours) do
      pluck(:variable, :value).to_h.symbolize_keys
    end
  end

  def self.footer_link
    Rails.cache.fetch(:footer_link, expires_in: 6.hours) do
      where(variable: %w[tg_support tg_group]).pluck(:variable, :description).to_h.symbolize_keys
    end
  end

  def self.fetch_value(key)
    all_cached[key]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[variable]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  private

  def clear_settings_cache
    Rails.cache.delete_multi(%i[settings footer_link])
  end
end
