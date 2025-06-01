require 'telegram/bot'

class TelegramBotWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'telegram_bot', retry: true

  TRACK_CACHE_PERIOD = 5.minutes

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
    ErrorMailer.send_error(error.message, error.full_message).deliver_later
  end

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
      return input_tracking_number(message) if message.chat.id == settings[:courier_tg_id].to_i

      handle_message(bot, message)
      # else bot.api.send_message(chat_id: message.from.id, text: I18n.t('tg_msg.error_data'))
    end
  end

  def handle_callback(bot, message)
    send(message.data.to_sym, bot, message) if respond_to?(message.data.to_sym, true)
  end

  def handle_message(bot, message)
    if message.text.present?
      process_message(message)
      send_firs_msg(bot, message.chat.id)
    elsif message.video.present?
      save_preview_video(bot, message)
    elsif message.photo.present?
      save_photo(message)
    else
      other_message(bot, message)
    end
  end

  def other_message(bot, message)
    TelegramJob.perform_later(msg: "Неизв. тип сообщения от #{message.chat.id}", id: Setting.fetch_value(:test_id))
    send_firs_msg(bot, message.chat.id)
  end

  def save_preview_video(bot, message)
    return unless settings[:admin_ids].split(',').include?(message.chat.id.to_s)

    bot.api.send_message(chat_id: message.chat.id, text: "ID видео:\n#{message.video.file_id}")
  end

  def save_photo(message)
    tg_id   = message.chat.id
    file_id = message.photo.last.file_id
    msg_id  = message.message_id
    TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id)
  end

  def process_message(message)
    tg_user = message.chat.as_json
    user    = User.find_or_create_by_tg(tg_user, true)
    unlock_user(user) unless user.started
    return if message.text == '/start'

    user.messages.create(text: message.text, tg_msg_id: message.message_id)
  end

  def unlock_user(user)
    msg = "User #{user.id} started bot"
    Rails.logger.info msg
    TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:test_id))
    # TODO: убрать со временем уведомление админа
    user.update(started: true, is_blocked: false)
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
    [user_state[:msg_id], user_state[:h_msg], message.message_id].each_with_index do |id, index|
      wait = (index + 1).seconds
      TelegramJob.set(wait: wait).perform_later(method: 'delete_msg', id: message.chat.id, msg_id: id)
    end
  end

  def i_paid(_bot, message)
    user         = User.find_by(tg_id: message.from.id)
    order_number = parse_order_number(message.message.text)
    order        = user.orders.find(order_number)
    # order = user.orders.find_by(msg_id: message.message.message_id)
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
    save_cache(order_number, message, msg)
  end

  def save_cache(order_number, message, msg)
    Rails.cache.write("user_#{message.message.chat.id}_state",
                      { order_id: order_number, msg_id: message.message.message_id, h_msg: msg.message_id },
                      expires_in: TRACK_CACHE_PERIOD)
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
