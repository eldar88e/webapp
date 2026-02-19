module Tg
  class ChatMember
    def initialize(status, chat_id)
      @status  = status
      @chat_id = chat_id
    end

    def self.call(status, chat_id)
      new(status, chat_id).handle_chat_member
    end

    def handle_chat_member
      user = User.find_by(tg_id: @chat_id)
      return Rails.logger.warn "User not found for chat member update: #{@chat_id}" if user.nil?

      if @status == 'member'
        user.update(is_blocked: false)
      elsif @status == 'kicked'
        user.update(is_blocked: true)
      end
      send_msg_to_user(user)
    end

    private

    def send_msg_to_user(user)
      msg = "Клиент #{@status == 'kicked' ? 'заблокировал' : 'разблокировал'} бот"
      user.messages.create(text: msg)
      send_welcome_msg(user) if @status == 'member'
    end

    def settings
      Setting.all_cached
    end

    def send_welcome_msg(user)
      msg = <<~MSG.squeeze(' ').chomp
        С возвращением #{user.first_name || user.first_name_raw}! 👋
        Мы рады снова приветствовать вас в #{Setting.fetch_value(:app_name)&.capitalize}!
        Мы по-прежнему здесь, чтобы помочь вам с заказами и ответить на любые вопросы.\n
        Чем можем быть полезны?
      MSG
      user.messages.create(text: msg, is_incoming: false, data: { markup: { markup: 'to_catalog' } })
    end
  end
end
