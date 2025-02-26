require 'telegram/bot'

class TelegramService
  MESSAGE_LIMIT = 4_090

  def initialize(message, id = nil, **args)
    @bot_token   = settings[:tg_token]
    @chat_id     = id == :courier ? settings[:courier_tg_id] : (id || settings[:admin_chat_id])
    @message     = message
    @message_id  = nil
    @markup      = args[:markup]
    @markup_url  = args[:markup_url]
    @markup_text = args[:markup_text] || 'Кнопка'
  end

  def self.call(msg, id = nil, **args)
    new(msg, id, **args).report
  end

  def report
    tg_send if bot_ready?
  end

  private

  def settings
    @settings ||= Setting.all_cached
  end

  def bot_ready?
    if @bot_token.present? && @chat_id.present? && @message.present?
      @message = "‼️‼️Development‼️‼️\n\n#{@message}" if Rails.env.development?
      true
    else
      Rails.logger.error 'Telegram chat ID or bot token not set!'
      false
    end
  end

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~>#+=|{}.!])/, '\\\\\1') # delete `
  end

  def tg_send
    message_count = (@message.size / MESSAGE_LIMIT) + 1
    markup        = form_markup
    message_count.times do
      text_part = next_text_part
      send_telegram_message(text_part, markup)
    end
    # TODO: Если нужно зафиксировать все msg_id нужно их поместить в array
    @message_id
  end

  def send_telegram_message(text_part, markup)
    [@chat_id.to_s.split(',')].flatten.each do |user_id|
      Telegram::Bot::Client.run(@bot_token) do |bot|
        @message_id = bot.api.send_message(
          chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2', reply_markup: markup
        ).message_id
      end
    rescue StandardError => e
      Rails.logger.error "Failed to send message to bot: #{e.message}"
      @message_id = e
    end
  end

  def form_keyboard
    buttons = []
    if @markup != 'new_order' && @markup != 'mailing'
      buttons << [Telegram::Bot::Types::InlineKeyboardButton.new(text: I18n.t("tg_btn.#{@markup}"),
                                                                 callback_data: @markup)]
      buttons += [order_btn('Изменить заказ'), ask_btn] if @markup == 'i_paid'
    else
      text_btn = @markup == 'mailing' ? (settings[:bot_btn_title].presence || 'Новый заказ') : 'Новый заказ'
      buttons += [order_btn(text_btn), ask_btn]
    end
    buttons
  end

  def form_url_keyboard
    url = "https://t.me/#{settings[:tg_main_bot]}?startapp=url=#{@markup_url}"
    [[Telegram::Bot::Types::InlineKeyboardButton.new(text: @markup_text, url: url)]]
  end

  def order_btn(btn_text)
    url = "https://t.me/#{settings[:tg_main_bot]}?startapp"
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: btn_text, url: url)]
  end

  def ask_btn
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Задать вопрос', url: settings[:tg_support].to_s)]
  end

  def form_markup
    return if @markup.nil? && @markup_url.nil?

    keyboard = @markup ? form_keyboard : form_url_keyboard
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  end

  def next_text_part
    part     = @message[0...MESSAGE_LIMIT]
    @message = @message[MESSAGE_LIMIT..] || ''
    part
  end
end
