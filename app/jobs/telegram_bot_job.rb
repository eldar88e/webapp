require 'telegram/bot'

class TelegramBotJob < ApplicationJob
  queue_as :bot_queue

  def perform(*args)
    setting = Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    Telegram::Bot::Client.run(setting[:tg_token]) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          Rails.logger.error "CallbackQuery"
        when Telegram::Bot::Types::Message
          handle_message(bot, message)
        else
          bot.api.send_message(chat_id: message.from.id, text: I18n.t('tg_msg.error_data'))
        end
      end
    rescue => e
      puts "+" * 80
      Rails.logger.error e.message
      puts "+" * 80
    end
  end

  private

  def handle_message(bot, message)
    case message.text
    when '/start'
      user = User.find_by(tg_id: message.chat.id)
      if user.blank?
        send_firs_msg(bot, message.chat.id)
        save_user(message.chat)
      end
    else
      send_firs_msg(bot, message.chat.id)
      # bot.api.send_message(chat_id: message.chat.id, text: I18n.t('tg_msg.error_msg'))
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
    ActionController::Base.default_url_options[:host] = 'https://webapp.open-ps.ru/'
    # video  = Rails.root.join('app/assets/images/first_animation.mp4')
    # video_url = ActionController::Base.helpers.image_url('first_animation.mp4')
    video_url = Rails.root.join('public/videos/first_animation.mp4')
    markup    = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
    bot.api.send_video(chat_id: chat_id, video: Faraday::UploadIO.new(video_url, 'video/mp4'), caption: I18n.t('tg_msg.start'), reply_markup: markup)
  rescue => e
    puts "+" * 80
    Rails.logger.error e.message
    puts "+" * 80
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
