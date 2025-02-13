require 'telegram/bot'

class TelegramMsgDelService
  def self.remove(chat_id, msg_id)
    Telegram::Bot::Client.run(Setting.fetch_value(:tg_token)) do |bot|
      response = bot.api.delete_message(chat_id: chat_id, message_id: msg_id)
      Rails.logger.info("Message #{msg_id} successfully deleted from chat #{chat_id}.")
      response
    rescue StandardError => e
      Rails.logger.warn("Failed to delete message #{msg_id} from chat #{chat_id}\n#{e}")
      false
    end
  end
end
