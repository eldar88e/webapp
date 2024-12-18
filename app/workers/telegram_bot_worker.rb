require 'telegram/bot'

class TelegramBotWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'telegram_bot', retry: true, lock: :until_executed

  TRACK_CACHE_PERIOD = 5.minutes

  def perform
    Telegram::Bot::Client.run(settings[:tg_token]) do |bot|
      Rails.application.config.telegram_bot = bot
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          handle_callback(bot, message)
        when Telegram::Bot::Types::Message
          handle_message(bot, message)
        else
          # bot.api.send_message(chat_id: message.from.id, text: I18n.t('tg_msg.error_data'))
        end
      rescue => e
        Rails.logger.error "#{self.class} | #{e.message}"
      end
    end
  end

  private

  def save_preview_video(bot, message)
    return unless settings[:admin_ids].split(',').include?(message.chat.id.to_s)

    bot.api.send_message(chat_id: message.chat.id, text: "ID Вашего видео:\n#{message.video.file_id}")
    true
  end

  def handle_callback(bot, message)
    self.send(message.data.to_sym, bot, message) if self.respond_to?(message.data.to_sym, true)
  end

  def handle_message(bot, message)
    User.find_or_create_by_tg(message.chat) # TODO: временно для перехода всех пользователей

    case message.text
    when '/start'
      # User.find_or_create_by_tg(message.chat)
      send_firs_msg(bot, message.chat.id)
    else
      if message.chat.id == settings[:courier_tg_id].to_i
        input_tracking_number(bot, message)
      else
        return save_preview_video(bot, message) if message.video.present?

        send_firs_msg(bot, message.chat.id)
      end
    end
  end

  def input_tracking_number(bot, message)
    user_state = Rails.cache.read("user_#{message.chat.id}_state")
    if user_state&.dig(:waiting_for_tracking)
      order = Order.find_by(id: user_state[:order_id])
      order.update(tracking_number: message.text, status: 'shipped')
      bot.api.send_message(
        chat_id: message.chat.id,
        text: I18n.t('tg_msg.track_num_save', order: user_state[:order_id], fio: user_state[:full_name], num: message.text)
      )
      [ user_state[:msg_id], user_state[:h_msg], message.message_id ].each do |id|
        bot.api.delete_message(chat_id: message.chat.id, message_id: id)
      end
      Rails.cache.delete("user_#{message.chat.id}_state")
    end
  end

  def i_paid(bot, message)
    user  = User.find_by(tg_id: message.from.id)
    order = user.orders.find_by(msg_id: message.message.message_id)
    order.update(status: :pending)
    bot.api.delete_message(chat_id: message.from.id, message_id: message.message.message_id)
  end

  def approve_payment(bot, message)
    order_number = parse_order_number(message.message.text)
    order        = Order.find(order_number)
    order.update(status: :processing)
    # bot.api.delete_message(chat_id: message.message.chat.id, message_id: message.message.message_id)
    # fio = parse_full_name(message.message.text)
    # bot.api.send_message(chat_id: message.message.chat.id, text: I18n.t('tg_msg.approved_pay', order: order_number, fio: fio))
  end

  def submit_tracking(bot, message)
    order_number = parse_order_number(message.message.text)
    full_name    = parse_full_name(message.message.text)
    msg          = bot.api.send_message(chat_id: message.message.chat.id,
                                        text: I18n.t('tg_msg.set_track_num', order: order_number, fio: full_name))
    Rails.cache.write(
      "user_#{message.message.chat.id}_state",
      { waiting_for_tracking: true, order_id: order_number, full_name: full_name,
        msg_id: message.message.message_id, h_msg: msg.message_id },
      expires_in: TRACK_CACHE_PERIOD
    )
  end

  def parse_order_number(text)
    text.match(/№(\d+)/)[1]
  end

  def parse_full_name(text)
    text[/ФИО:\s*(.+?)\n\n/, 1]
  end

  def send_firs_msg(bot, chat_id)
    first_btn = initialize_first_btn(chat_id)
    markup    = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: first_btn)
    caption   = settings[:preview_msg]&.gsub('\\n', "\n") # I18n.t('tg_msg.start')
    bot.api.send_video(
      chat_id: chat_id, video: settings[:first_video_id], caption: caption, reply_markup: markup
    )
  end

  def initialize_first_btn(chat_id)
    [
      [ Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Каталог', url: "https://t.me/#{settings[:tg_main_bot]}?startapp=#{chat_id}"
      ) ],
      [ Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Перейти в СДВГ-чат', url: settings[:tg_group]
      ) ],
      [ Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Задать вопрос', url: settings[:tg_support]
      ) ]
    ]
  end

  def settings
    Rails.cache.fetch(:settings, expires_in: 6.hours) do
      Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    end
  end
end
