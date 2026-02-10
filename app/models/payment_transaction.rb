class PaymentTransaction < ApplicationRecord
  belongs_to :order

  has_many :api_logs, as: :loggable, dependent: :nullify

  enum :status, { created: 0, initialized: 1, paid: 2, checking: 3, approved: 4, cancelled: 5, failed: 6, overdue: 7 }
  enum :payment_method, { card: 1, spb: 2 }

  before_update :set_time_for_status, if: -> { status_changed? }

  private

  def set_time_for_status
    column = "#{status}_at"
    self[column] = Time.current if has_attribute?(column) && self[column].blank?
  end
end
