class Message < ApplicationRecord
  belongs_to :user, primary_key: :tg_id, foreign_key: :tg_id, inverse_of: :messages

  after_create_commit :send_to_telegram, if: -> { !is_incoming? }
  after_create_commit :broadcast_admin_chat
  after_create_commit :notify_admin, if: -> { is_incoming? }

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
    msg = "✉️ Входящее сообщение\n️\n👤: #{user.full_name.presence || "User #{user.id}"}"
    msg += "\n       @#{user.username}" if user.username.present?
    msg += "\n\n#{text}"
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
  end

  def send_to_telegram
    ConsumerSenderTgJob.perform_later(msg_id: id, id: user.tg_id, msg: text, data: parsed_data)
  end

  def broadcast_admin_chat
    broadcast_append_later_to(
      "admin_chat_#{user.id}", partial: '/admin/messages/msg',
                               locals: { message: self, current_user: user }, target: 'messages'
    )
  end
end
