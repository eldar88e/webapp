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
      if @status == 'member'
        user&.update(is_blocked: false)
      elsif @status == 'kicked'
        user&.update(is_blocked: true)
      end
      notify_admin(user)
    end

    private

    def notify_admin(user)
      msg = "User #{user&.id} #{@status ? 'blocked' : 'unblocked'} bot"
      TelegramJob.perform_later(msg: msg, id: settings[:test_id])
      Rails.logger.info "User #{user&.id} #{@status ? 'blocked' : 'unblocked'} bot"
    end
  end
end
