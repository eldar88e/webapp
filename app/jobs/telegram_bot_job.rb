require 'telegram/bot'

class TelegramBotJob < ApplicationJob
  queue_as :bot_queue
  VIDEO_URL = 'https://webapp.open-ps.ru/videos/first_animation.mp4'

  def perform(*args)
    setting = Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)

    Telegram::Bot::Client.run(setting[:tg_token]) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          handle_callback(message)
        when Telegram::Bot::Types::Message
          handle_message(bot, message)
        else
          bot.api.send_message(chat_id: message.from.id, text: I18n.t('tg_msg.error_data'))
        end
      rescue => e
        puts "+" * 80
        Rails.logger.error e.message
        puts "+" * 80
      end
    end
  end

  private

  def handle_callback(message)
    self.send(message.data.to_sym, message) if self.respond_to?(message.data.to_sym, true)
  end

  def i_paid(message)
    user  = User.find_by(tg_id: message.from.id)
    order = user.orders.find_by(msg_id: message.message.message_id)
    order.update(status: :pending)
  end

  def approve_payment(message)
    text         = message.message.text
    order_number = text.match(/№(\d+)/)[1]
    order        = Order.find(order_number)
    order.update(status: :processing)
  end

  def handle_message(bot, message)
    case message.text
    when '/start'
      user = User.find_by(tg_id: message.chat.id)
      save_user(message.chat) if user.blank?
      send_firs_msg(bot, message.chat.id)
    else
      send_firs_msg(bot, message.chat.id)
    end
  end

  def send_firs_msg(bot, chat_id)
    keyboard = [
      [ Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Каталог', url: "https://t.me/atominexbot?startapp=#{chat_id}"
      ) ],
      [ Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Перейти в СДВГ-чат', url: 'https://t.me/+EbVQcAOIdsk1Njhk'
      ) ],
      [ Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Задать вопрос', url: 'https://t.me/eczane_store'
      ) ]
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
    bot.api.send_video(chat_id: chat_id, video: VIDEO_URL, caption: I18n.t('tg_msg.start'), reply_markup: markup)
  end

  def save_user(chat)
    User.create(
      tg_id: chat.id,
      username: chat.username,
      first_name: chat.first_name,
      last_name: chat.last_name,
      full_name: "#{chat.first_name} #{chat.last_name}",
      email: generate_email(chat.id),
      password: Devise.friendly_token[0, 20]
    )
  end

  def generate_email(chat_id)
    "telegram_user_#{chat_id}@example.com"
  end
end
