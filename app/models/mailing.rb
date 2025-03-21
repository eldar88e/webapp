class Mailing < ApplicationRecord
  MARKUP = { markup: 'mailing' }.freeze

  belongs_to :user

  enum :target, { all_users: 0, ordered: 1, no_ordered: 2, blocked: 3, add_cart: 4 } # users: 5

  validates :send_at, presence: true
  validates :message, presence: true, length: { maximum: 4000 }

  # after_create :schedule_mailing_job

  private

  def schedule_mailing_job
    delay = [send_at - Time.current, 0].max
    msg   = "Запущена рассылка на #{I18n.t("target.#{target}")}"
    TelegramJob.set(wait: delay).perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
    MailingJob.set(wait: delay).perform_later(filter: target, message: message, markup: MARKUP, id: id)
  end
end
