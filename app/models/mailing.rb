class Mailing
  include ActiveModel::Model

  attr_accessor :filter, :message, :scheduled_at

  validates :filter, inclusion: { in: %w[ordered no_ordered all], message: "must be 'ordered', 'no_ordered', or 'all'" }
  validates :message, presence: true

  def scheduled_at=(value)
    @scheduled_at = Time.zone.parse(value) rescue nil
  end
end
