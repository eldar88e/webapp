require 'telegram/bot'

class TelegramBotWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'telegram_bot', retry: true

  TRACK_CACHE_PERIOD = 5.minutes

  def perform
    return unless tg_token_present?

    Telegram::Bot::Client.run(settings[:tg_token]) do |bot|
      Rails.application.config.telegram_bot = bot
      bot.listen do |message|
        process_bot(bot, message)
      rescue StandardError => e
        Rails.logger.error "#{self.class} | #{e.message}"
        ErrorMailer.send_error("Stage 2 #{error.message}", error.full_message).deliver_later
      end
    rescue StandardError => e
      Rails.logger.error "#{self.class} | #{e.message}"
      ErrorMailer.send_error("Stage 1 #{error.message}", error.full_message).deliver_later
      raise e
    end
  end

  private

  def tg_token_present?
    return true if settings[:tg_token].present?

    Rails.logger.error('tg_token not specified!')
    Rails.application.config.telegram_bot = nil
    false
  end

  def process_bot(bot, message)
    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_callback(bot, message)
    when Telegram::Bot::Types::Message
      handle_message(bot, message)
      # else bot.api.send_message(chat_id: message.from.id, text: I18n.t('tg_msg.error_data'))
    end
  end

  def save_preview_video(bot, message)
    return send_firs_msg(bot, message.chat.id) unless settings[:admin_ids].split(',').include?(message.chat.id.to_s)

    bot.api.send_message(chat_id: message.chat.id, text: "ID Вашего видео:\n#{message.video.file_id}")
  end

  def handle_callback(bot, message)
    send(message.data.to_sym, bot, message) if respond_to?(message.data.to_sym, true)
  end

  def handle_message(bot, message)
    return input_tracking_number(message) if message.chat.id == settings[:courier_tg_id].to_i

    if message.text.present?
      process_message(message)
    elsif message.video.present?
      return save_preview_video(bot, message)
    end
    send_firs_msg(bot, message.chat.id)
  end

  def process_message(message)
    tg_user = message.chat.as_json
    user    = User.find_or_create_by_tg(tg_user, true) # не обновляет username если user существует
    user.update(started: true, is_blocked: false, username: tg_user['username']) # тех кто зарегался через webapp
    return if message.text == '/start'

    save_message(message, user)
    notify_admins(message, user)
  end

  def save_message(message, user)
    Message.create!(tg_id: user.tg_id, text: message.text, tg_msg_id: message.message_id)
  rescue StandardError => e
    # TODO: Возможно в дальнейшем убрать!
    Rails.logger.error "No save tg msg #{message.from.id}, #{message.text}, #{message.message_id}, #{e.message}"
  end

  def notify_admins(message, user)
    msg = "‼️Входящее сообщение‼️\n️\n"
    name = message.from.username.present? ? "@#{message.from.username}" : (user.full_name.presence || "User #{user.id}")
    msg += "От: #{name}\n\n"
    msg += message.text
    TelegramJob.perform_later(msg: msg, id: settings[:admin_ids])
  end

  def input_tracking_number(message)
    user_state = Rails.cache.read("user_#{message.chat.id}_state")
    return if user_state&.dig(:order_id).blank?

    order = Order.find(user_state[:order_id])
    order.update(tracking_number: message.text, status: :shipped)

    [user_state[:msg_id], user_state[:h_msg], message.message_id].each do |id|
      TelegramJob.perform_later(method: 'delete_msg', id: message.chat.id, msg_id: id)
      sleep 0.3
    end
    Rails.cache.delete("user_#{message.chat.id}_state")
  end

  def i_paid(_bot, message)
    user  = User.find_by(tg_id: message.from.id)
    order = user.orders.find_by(msg_id: message.message.message_id)
    order.update(status: :paid)
  end

  def approve_payment(bot, message)
    order_number = parse_order_number(message.message.text)
    order        = Order.find(order_number)
    order.update(status: :processing)
    bot.api.delete_message(chat_id: message.message.chat.id, message_id: message.message.message_id)
  end

  def submit_tracking(bot, message)
    order_number = parse_order_number(message.message.text)
    full_name    = parse_full_name(message.message.text)
    msg          = bot.api.send_message(chat_id: message.message.chat.id,
                                        text: I18n.t('tg_msg.set_track_num', order: order_number, fio: full_name))
    Rails.cache.write(
      "user_#{message.message.chat.id}_state",
      { order_id: order_number, msg_id: message.message.message_id, h_msg: msg.message_id },
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
    first_btn = initialize_first_btn
    markup    = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: first_btn)
    caption   = settings[:preview_msg].to_s.gsub('\\n', "\n")
    if settings[:first_video_id].present?
      bot.api.send_video(chat_id: chat_id, video: settings[:first_video_id], caption: caption, reply_markup: markup)
    else
      bot.api.send_message(chat_id: chat_id, text: caption, reply_markup: markup)
    end
  end

  def initialize_first_btn
    [[Telegram::Bot::Types::InlineKeyboardButton.new(
      text: settings[:bot_btn_title], url: "https://t.me/#{settings[:tg_main_bot]}?startapp"
    )],
     [Telegram::Bot::Types::InlineKeyboardButton.new(text: settings[:group_btn_title], url: settings[:tg_group])],
     [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Задать вопрос', url: settings[:tg_support])]]
  end

  def settings
    Setting.all_cached
  end
end
