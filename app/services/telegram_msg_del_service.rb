require 'telegram/bot'

class TelegramMsgDelService
  def self.remove(chat_id, msg_id)
    Telegram::Bot::Client.run(Setting.fetch_value(:tg_token)) do |bot|
      response = bot.api.delete_message(chat_id: chat_id, message_id: msg_id)

      if response
        Rails.logger.info("Message #{msg_id} successfully deleted from chat #{chat_id}.")
        true
      else
        Rails.logger.error("Failed to delete message #{msg_id} from chat #{chat_id}: #{response}.")
        false
      end
    rescue Telegram::Bot::Exceptions::ResponseError => e
      Rails.logger.error("Failed to delete message #{msg_id} from chat #{chat_id}: #{response}.\nError: #{e}")
      false
    end
  end
end
