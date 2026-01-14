module Tg
  class ChatMember
    def initialize(bot:, status:, chat_id:)
      @bot     = bot
      @status  = status
      @chat_id = chat_id
    end

    def self.call(bot, status)
      new(bot, status).handle_chat_member
    end

    def handle_chat_member
      user = User.find_by(tg_id: @chat_id)
      return Rails.logger.warn "User not found for chat member update: #{@chat_id}" if user.nil?

      if @status == 'member'
        user.update(is_blocked: false)
      elsif @status == 'kicked'
        user.update(is_blocked: true)
      end
      notify_admin(user)
    end

    private

    def notify_admin(user)
      user_name = make_user_name(user)
      msg = "#{user_name}\n#{@status ? 'blocked' : 'unblocked'} bot"
      markup = { markup_url: "admin/users/#{user.id}", markup_text: '👤 подробнее' }
      TelegramJob.perform_later(msg: msg, id: settings[:test_id], **markup)
      Rails.logger.info "User #{user&.id} #{@status ? 'blocked' : 'unblocked'} bot"
    end

    def settings
      Setting.all_cached
    end

    def make_user_name(user)
      msg = "User ##{user.id}"
      msg += "\n(@#{user.username})" if user.username.present?
      msg += user.full_name.present? ? "\n#{user.full_name}" : "\n#{user.full_name_raw}"
      msg
    end
  end
end
