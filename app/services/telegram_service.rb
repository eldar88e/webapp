require 'telegram/bot'

class TelegramService
  MESSAGE_LIMIT = 4_090

  def initialize(message, id = nil)
    @message   = message
    @chat_id   = id == :courier ? settings[:courier_tg_id] : (id || settings[:admin_chat_id])
    @bot_token = settings[:tg_token]
  end

  def self.call(msg, id = nil, **args)
    new(msg, id).report(**args)
  end

  def report(**args)
    @markup      = args[:markup]
    @markup_url  = args[:markup_url]
    @markup_text = args[:markup_text] || 'Кнопка'
    tg_send if @message.present? && credential_exists?
  end

  private

  def settings
    @settings ||= Setting.all_cached
  end

  def credential_exists?
    return true if @chat_id.present? || @bot_token.present?

    Rails.logger.error 'Telegram chat ID or bot token not set!'
    false
  end

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~>#+=|{}.!])/, '\\\\\1') # delete `
  end

  def tg_send
    message_id    = nil
    message_count = (@message.size / MESSAGE_LIMIT) + 1
    @message      = "‼️‼️Development‼️‼️\n\n#{@message}" if Rails.env.development?
    markup        = form_markup
    message_count.times do
      text_part = next_text_part
      [@chat_id.to_s.split(',')].flatten.each do |user_id|
        Telegram::Bot::Client.run(@bot_token) do |bot|
          message_id = bot.api.send_message(
            chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2', reply_markup: markup
          ).message_id
        end
      rescue StandardError => e
        Rails.logger.error "Failed to send message to bot: #{e}"
        message_id = e
      end
    end
    # TODO: Если нужно зафиксировать все msg_id нужно их поместить в array
    message_id
  end

  def form_keyboard
    buttons = []
    if @markup != 'new_order' && @markup != 'mailing'
      buttons << [Telegram::Bot::Types::InlineKeyboardButton.new(text: I18n.t("tg_btn.#{@markup}"),
                                                                 callback_data: @markup)]
      buttons += [order_btn('Изменить заказ'), ask_btn] if @markup == 'i_paid'
    else
      text_btn = @markup == 'mailing' ? 'Перейти в каталог' : 'Новый заказ'
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
