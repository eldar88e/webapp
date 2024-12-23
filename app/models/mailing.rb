class Mailing
  include ActiveModel::Model

  attr_accessor :filter, :message, :scheduled_at

  validates :filter, inclusion: { in: %w[ordered no_ordered all], message: "должен быть #{I18n.t('filters.ordered')}, #{I18n.t('filters.no_ordered')}, или #{I18n.t('filters.all')}" }
  validates :message, presence: true

  def scheduled_at=(value)
    @scheduled_at = Time.zone.parse(value) rescue nil
  end
end
