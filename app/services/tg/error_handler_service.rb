module Tg
  class ErrorHandlerService
    def initialize(**args)
      @error    = args[:error]
      @user     = args[:user]
      @business = args[:business]
    end

    def self.call(**args)
      new(**args).handle_error
    end

    # rubocop:disable Metrics/MethodLength
    def handle_error
      if !@error.is_a?(Telegram::Bot::Exceptions::ResponseError)
        notify_email_admin('Telegram new sending error')
      elsif @error.message.include?('chat not found')
        update_user({ started: false })
      elsif @error.message.include?('bot was blocked')
        update_user({ is_blocked: true })
      elsif @error.message.include?('user is deactivated')
        update_user({ is_blocked: true }) # TODO: maybe add new field for deleted chat
        @user.messages.create(text: 'Клиент деактивировал аккаунт')
      else
        notify_email_admin('Telegram new sending type error')
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def notify_email_admin(msg)
      Rails.logger.error("#{msg}: #{@error.message}")

      AdminMailer.send_error("#{msg} #{@error.message}", @error.full_message).deliver_later
    end

    def update_user(attrs)
      @user.update(attrs)
      return if @business.blank?

      msg = attrs[:started] == false ? 'не нажатия на старт!' : 'блокировки бота клиентом или деактивации аккаунта!'
      notify_admin(msg)
    end

    def notify_admin(message)
      client_name = @user.username.present? ? "@#{@user.username}" : "ID ##{@user.id}"
      msg         = "Клиенту #{client_name} не пришло бизнес сообщение по причине"
      TelegramService.call("#{msg} #{message}", Setting.fetch_value(:test_id))
    end
  end
end
