require 'telegram/bot'

class TelegramService
  MESSAGE_LIMIT = 4_090

  def initialize(message, id = nil, msg_id = nil)
    @message = message
    settings = Rails.cache.fetch(:settings, expires_in: 6.hours) do
      Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    end
    @chat_id   = id || settings[:admin_chat_id]
    @bot_token = settings[:tg_token]
    @msg_id    = msg_id
  end

  def self.call(msg, id=nil)
    new(msg, id).report
  end

  def self.delete_msg(msg, id, msg_id)
    new(msg, id, msg_id).send(:delete_message)
  end

  def report
    tg_send if @message.present? && credential_exists?
  end

  private

  def delete_message
    Telegram::Bot::Client.run(@bot_token) do |bot|
      response = bot.api.delete_message(chat_id: @chat_id, message_id: @msg_id)

      if response
        Rails.logger.info("Message #{@msg_id} successfully deleted from chat #{@chat_id}.")
        true
      else
        Rails.logger.error("Failed to delete message #{@msg_id} from chat #{@chat_id}: #{response}.")
        false
      end
    rescue Telegram::Bot::Exceptions::ResponseError => e
      Rails.logger.error("Failed to delete message #{@msg_id} from chat #{@chat_id}: #{response}.\nError: #{e}")
      false
    end
  end

  def credential_exists?
    return true if @chat_id.present? || @bot_token.present?

    Rails.logger.error 'Telegram chat ID or bot token not set!'
    false
  end

  def tg_send
    return send_messages_to_user(@chat_id) if @chat_id.instance_of?(Integer)

    [@chat_id.to_s.split(',')].flatten.each { |id| send_messages_to_user(id) }
    nil
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~>#+=|{}.!])/, '\\\\\1') # delete `
  end

  def send_messages_to_user(user_id)
    message_id    = nil
    message_count = (@message.size / MESSAGE_LIMIT) + 1
    @message      = "‼️Dev #{@message}" if Rails.env.development?
    Telegram::Bot::Client.run(@bot_token) do |bot|
      message_count.times do
        text_part  = next_text_part
        response   = bot.api.send_message(chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2')
        message_id = response.message_id
      end
    end
    message_id
  end

  def next_text_part
    part = @message[0...MESSAGE_LIMIT]
    @message = @message[MESSAGE_LIMIT..] || ''
    part
  end
end
