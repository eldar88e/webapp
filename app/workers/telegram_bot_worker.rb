require 'telegram/bot'

class TelegramBotWorker
  include Sidekiq::Job

  sidekiq_options queue: 'telegram_bot', retry: true

  TG_MESSAGE_DELAY = 0.3

  def perform
    return unless tg_token_present?

    Telegram::Bot::Client.run(settings[:tg_token]) do |bot|
      Rails.application.config.telegram_bot = bot
      bot.listen { |message| process_bot(bot, message) }
    rescue StandardError => e
      process_error e
      # raise e
      sleep 5
      retry
    end
  end

  private

  def process_error(error)
    Rails.logger.error "#{self.class} | #{error.message}"
    AdminMailer.send_error(error.message, error.full_message).deliver_later
  end

  def tg_token_present?
    return true if settings[:tg_token].present?

    Rails.logger.error('tg_token not specified!')
    Rails.application.config.telegram_bot = nil
    false
  end

  # rubocop:disable Metrics/MethodLength
  def process_bot(bot, message)
    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_callback(bot, message)
    when Telegram::Bot::Types::Message
      return input_tracking_number(message) if message.chat.id == settings[:courier_tg_id].to_i

      handle_message(bot, message)
    when Telegram::Bot::Types::ChatMember
      handle_chat_member(bot, message)
    else
      msg = "Unknown TG message type: #{message.class}"
      msg += "\n\n#{message.to_json}"
      Rails.logger.error msg
      TelegramJob.perform_later(msg: msg, id: settings[:test_id])
    end
  end
  # rubocop:enable Metrics/MethodLength

  def handle_chat_member(bot, message)
    Tg::ChatMember.call(bot: bot, status: message.new_chat_member.status, chat_id: message.chat.id)
  end

  def handle_callback(bot, message)
    Tg::TelegramCallbackService.call(bot, message)
  end

  def handle_message(bot, message)
    Tg::DispatcherService.call(bot, message)
  end

  def input_tracking_number(message)
    user_state = Rails.cache.read("user_#{message.chat.id}_state")
    return if user_state&.dig(:order_id).blank?

    order = Order.find(user_state[:order_id])
    order.update(tracking_number: message.text, status: :shipped)
    delete_old_msg(user_state, message)
    Rails.cache.delete("user_#{message.chat.id}_state")
  end

  def delete_old_msg(user_state, message)
    [user_state[:msg_id], user_state[:h_msg], message.message_id].each.with_index(1) do |msg_id, idx|
      wait = (idx * TG_MESSAGE_DELAY).seconds
      TelegramJob.set(wait: wait).perform_later(method: 'delete_msg', id: message.chat.id, msg_id: msg_id)
    end
  end

  def settings
    Setting.all_cached
  end
end
