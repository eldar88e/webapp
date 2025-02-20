class Mailing
  include ActiveModel::Model

  attr_accessor :filter, :message, :scheduled_at

  FILTERS = %w[ordered no_ordered all is_blocked add_cart users].freeze

  validates :filter,
            inclusion: { in: FILTERS,
                         message: "должен быть #{I18n.t('filters.ordered')}, #{I18n.t('filters.no_ordered')}, или #{I18n.t('filters.all')}" }
  validates :message, presence: true

  def scheduled_at=(value)
    @scheduled_at = begin
      Time.zone.parse(value)
    rescue StandardError
      nil
    end
  end
end
