class Message < ApplicationRecord
  SKIP_MSG_NOTICE = ['/start', 'Клиент заблокировал бот'].freeze

  belongs_to :user, primary_key: :tg_id, foreign_key: :tg_id, inverse_of: :messages
  belongs_to :reply_to, class_name: 'Message', optional: true
  belongs_to :manager, class_name: 'User', optional: true, inverse_of: :managed_messages

  before_validation { self.text = text&.strip }

  after_create_commit :send_to_telegram, if: -> { !is_incoming? }
  after_create_commit :broadcast_admin_chat
  after_create_commit :notify_admin, if: -> { is_incoming? }
  after_destroy_commit :delete_from_telegram, if: -> { tg_msg_id.present? }

  # validates :text, presence: true TODO: add validation text or data

  ransacker :user_first_name do
    Arel.sql('users.first_name')
  end

  ransacker :user_middle_name do
    Arel.sql('users.middle_name')
  end

  ransacker :user_last_name do
    Arel.sql('users.last_name')
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[user_first_name user_middle_name user_last_name created_at is_incoming]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  def parsed_data
    data.present? ? data.deep_symbolize_keys : {}
  end

  private

  def notify_admin
    return if SKIP_MSG_NOTICE.include?(text)
    return if Setting.fetch_value(:admin_ids).to_s.split(',').include?(tg_id.to_s)

    markup = { markup_url: "admin/messages&chat_id=#{tg_id}", markup_text: '💬 Перейти к сообщению' }
    msg    = build_notice_msg
    TelegramJob.set(wait: 1.second)
               .perform_later(msg: msg, id: Setting.fetch_value(:admin_ids), **markup)
    WebPushNoticeJob.perform_later(title: 'Новое сообщение', body: msg)
  end

  # rubocop:disable Metrics/AbcSize
  def build_notice_msg
    msg = "✉️ Входящее сообщение\n\n️🆔  #{user.id}"
    msg += "\n👤  #{user.full_name.presence || user.first_name_raw.presence || user.tg_id}"
    msg += "\n🔗  @#{user.username}" if user.username.present?
    msg += "\n\n💬  #{text}" if text.present?
    msg += "\n\n📎️  #{data['type']}" if data.present?
    msg
  end
  # rubocop:enable Metrics/AbcSize

  def send_to_telegram
    data = parsed_data
    data[:reply_to_message_id] = reply_to.tg_msg_id if reply_to&.tg_msg_id.present?
    ConsumerSenderTgJob.perform_later(msg_id: id, id: user.tg_id, msg: text, data: data)
  end

  def broadcast_admin_chat
    broadcast_append_later_to(
      "admin_chat_#{user.id}", partial: '/admin/messages/msg',
                               locals: { message: self }, target: 'messages'
    )
  end

  def delete_from_telegram
    TelegramJob.perform_later(id: tg_id, msg_id: tg_msg_id, method: 'delete_msg')
  end
end
