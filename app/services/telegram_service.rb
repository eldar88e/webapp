require 'telegram/bot'

class TelegramService
  MESSAGE_LIMIT = 4_090

  def initialize(message, id = nil, msg_id = nil)
    @message   = message
    @chat_id   = id == :courier ? settings[:courier_tg_id] : (id || settings[:admin_chat_id])
    @bot_token = settings[:tg_token]
    @msg_id    = msg_id
  end

  def self.call(msg, id = nil, **args)
    new(msg, id).report(**args)
  end

  def self.delete_msg(msg, id, msg_id)
    new(msg, id, msg_id).send(:delete_message)
  end

  def report(**args)
    @markup      = args[:markup]
    @markup_url  = args[:markup_url]
    @markup_text = args[:markup_text] || 'Кнопка'
    tg_send if @message.present? && credential_exists?
  end

  private

  def settings
    Rails.cache.fetch(:settings, expires_in: 6.hours) do
      Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    end
  end

  def delete_message
    Telegram::Bot::Client.run(@bot_token) do |bot|
      response = bot.api.delete_message(chat_id: @chat_id, message_id: @msg_id)

      if response
        Rails.logger.info("Message #{@msg_id} successfully deleted from chat #{@chat_id}.")
        true
      else
        Rails.logger.error("Failed to delete message #{@msg_id} from chat #{@chat_id}: #{response}.")
        false
      end
    rescue Telegram::Bot::Exceptions::ResponseError => e
      Rails.logger.error("Failed to delete message #{@msg_id} from chat #{@chat_id}: #{response}.\nError: #{e}")
      false
    end
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
    [@chat_id.to_s.split(',')].flatten.each do |user_id|
      message_count.times do
        Telegram::Bot::Client.run(@bot_token) do |bot|
            text_part = next_text_part
            response  = bot.api.send_message(
              chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2', reply_markup: markup
            )
            message_id = response.message_id
        end
      rescue => e
        message_id = e
      end
    end
    # TODO: Если нужно зафиксировать все msg_id нужно их поместить в array
    message_id
  end

  def form_keyboard
    buttons = []
    if @markup != 'new_order' && @markup != 'mailing'
      buttons << [Telegram::Bot::Types::InlineKeyboardButton.new(text: I18n.t("tg_btn.#{@markup}"), callback_data: @markup)]
      buttons += [order_btn('Изменить заказ'), ask_btn] if @markup == 'i_paid'
    else
      text_btn = @markup != 'mailing' ? 'Новый заказ' : 'Перейти в каталог'
      buttons += [order_btn(text_btn), ask_btn]
    end
    buttons
  end

  def form_url_keyboard
    url  = "https://t.me/#{settings[:tg_main_bot]}?startapp=#{@markup_url}"
    [[Telegram::Bot::Types::InlineKeyboardButton.new(text: @markup_text, url: url)]]
  end

  def order_btn(btn_text)
    url  = "https://t.me/#{settings[:tg_main_bot]}?startapp"
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: btn_text, url: url)]
  end

  def ask_btn
    [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Задать вопрос', url: "#{settings[:tg_support]}")]
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
