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
          handle_callback(bot, message)
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

  def handle_callback(bot, message)
    self.send(message.data.to_sym, bot, message) if self.respond_to?(message.data.to_sym, true)
  end

  def handle_message(bot, message)
    case message.text
    when '/start'
      user = User.find_by(tg_id: message.chat.id)
      save_user(message.chat) if user.blank?
      send_firs_msg(bot, message.chat.id)
    else
      user_state = Rails.cache.read("user_#{message.from.id}_state")
      if user_state&.dig(:waiting_for_tracking)
        order = Order.find_by(id: user_state[:order_id])
        order.update(tracking_number: message.text, status: 'shipped')
        bot.api.send_message(chat_id: message.chat.id, text: "Трек-номер для закакза №#{user_state[:order_id]} сохранён: #{message.text}")
        bot.api.delete_message(chat_id: message.from.id, message_id: user_state[:msg_id])
        Rails.cache.delete("user_#{message.from.id}_state")
      else
        send_firs_msg(bot, message.chat.id)
      end
    end
  end

  def i_paid(bot, message)
    user  = User.find_by(tg_id: message.from.id)
    order = user.orders.find_by(msg_id: message.message.message_id)
    order.update(status: :pending)
    bot.api.delete_message(chat_id: message.from.id, message_id: message.message.message_id)
  end

  def submit_tracking(bot, message)
    order_number = parse_order_number(message.message.text)
    Rails.cache.write(
      "user_#{message.from.id}_state",
      { waiting_for_tracking: true, order_id: order_number, msg_id: message.message.message_id },
      expires_in: 1.minute
    )
    bot.api.send_message(chat_id: message.from.id, text: "Введите трек-номер для заказа №#{order_number} в чат:")
  end

  def approve_payment(bot, message)
    order_number = parse_order_number(message.message.text)
    order        = Order.find(order_number)
    order.update(status: :processing)
    bot.api.delete_message(chat_id: message.from.id, message_id: message.message.message_id)
  end

  def parse_order_number(text)
    text.match(/№(\d+)/)[1]
  end

  def send_firs_msg(bot, chat_id)
    first_btn = initialize_first_btn(chat_id)
    markup    = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: first_btn)
    bot.api.send_video(chat_id: chat_id, video: VIDEO_URL, caption: I18n.t('tg_msg.start'), reply_markup: markup)
  end

  def initialize_first_btn(chat_id)
    [
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
  end

  def save_user(chat)
    User.create(
      tg_id: chat.id,
      username: chat.username,
      first_name: chat.first_name,
      last_name: chat.last_name,
      middle_name: chat.last_name,
      email: generate_email(chat.id),
      password: Devise.friendly_token[0, 20]
    )
  end

  def generate_email(chat_id)
    "telegram_user_#{chat_id}@example.com"
  end
end
