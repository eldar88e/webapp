class Mailing < ApplicationRecord
  belongs_to :user

  enum :target, { all_users: 0, ordered: 1, no_ordered: 2, blocked: 3, add_cart: 4, subscriptions: 5 } # , users: 6

  before_validation { self.scheduled_at ||= Time.current }

  validates :scheduled_at, presence: true
  validates :message, presence: true, length: { maximum: 4000 }

  after_create :schedule_mailing_job
  after_update :set_end_time, if: -> { saved_change_to_completed?(from: false, to: true) }

  private

  def schedule_mailing_job
    delay = [scheduled_at - Time.current, 0].max
    msg   = "Запущена рассылка для:\n#{I18n.t("target.#{target}")}"
    TelegramJob.set(wait: delay).perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
    MailingJob.set(wait: delay).perform_later(id: id)
  end

  def set_end_time
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(end_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
