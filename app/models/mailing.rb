class Mailing
  include ActiveModel::Model

  attr_accessor :filter, :message
  attr_reader :scheduled_at

  FILTERS = %w[ordered no_ordered all is_blocked add_cart users].freeze

  validates :filter, inclusion: { in: FILTERS, message: I18n.t('errors.messages.filter_range') }
  validates :message, presence: true

  def scheduled_at=(value)
    @scheduled_at = begin
      Time.zone.parse(value)
    rescue StandardError
      nil # TODO: нужна ошибка что бы выдать notice в controller
    end
  end
end
