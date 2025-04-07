class Mailing < ApplicationRecord
  belongs_to :user

  enum :target, { all_users: 0, ordered: 1, no_ordered: 2, blocked: 3, add_cart: 4, subscriptions: 5 } # , users: 6

  before_validation { self.send_at ||= Time.current }

  validates :send_at, presence: true
  validates :message, presence: true, length: { maximum: 4000 }

  after_create :schedule_mailing_job

  private

  def schedule_mailing_job
    delay = [send_at - Time.current, 0].max
    msg   = "Запущена рассылка для:\n#{I18n.t("target.#{target}")}"
    TelegramJob.set(wait: delay).perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
    MailingJob.set(wait: delay).perform_later(id: id)
  end
end
