class Setting < ApplicationRecord
  validates :variable, presence: true, uniqueness: true

  after_commit :clear_settings_cache, on: [ :create, :update, :destroy ]

  def self.fetch_value(key)
    result = Rails.cache.fetch(:settings, expires_in: 6.hours) do
      Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    end
    result[key]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[variable]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  private

  def clear_settings_cache
    Rails.cache.delete(:settings)
    Rails.cache.fetch(:settings, expires_in: 6.hours) do
      Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    end
  end
end
