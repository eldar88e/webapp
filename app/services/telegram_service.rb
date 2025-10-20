require 'telegram/bot'

class TelegramService
  MESSAGE_LIMIT = 4_090

  def initialize(message, id = nil, **args)
    @bot_token  = args[:tg_token] || settings[:tg_token]
    @chat_id    = id == :courier ? settings[:courier_tg_id] : (id || settings[:admin_chat_id])
    @message    = message
    @message_id = nil
    @markups    = markup_params(args)
  end

  def self.call(msg, id = nil, **args)
    new(msg, id, **args).report
  end

  def report
    tg_send if bot_ready?
  end

  private

  def bot_ready?
    if @bot_token.present? && @chat_id.present? && @message.present?
      @message = "‼️‼️Development‼️‼️\n\n#{@message}" if Rails.env.development?
      true
    else
      Rails.logger.error 'Telegram chat ID or bot token not set!'
      false
    end
  end

  def tg_send
    message_count = (@message.size / MESSAGE_LIMIT) + 1
    markup        = build_markup
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

  def build_markup
    Tg::MarkupService.call(@markups)
  end

  def next_text_part
    part     = @message[0...MESSAGE_LIMIT]
    @message = @message[MESSAGE_LIMIT..] || ''
    part
  end

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_\[\]()~>#+=|{}.!])/, '\\\\\1') # delete `,*
  end

  def markup_params(args)
    {
      markup: args[:markup],
      markup_url: args[:markup_url],
      markup_text: args[:markup_text],
      markup_ext_url: args[:markup_ext_url],
      markup_ext_text: args[:markup_ext_text] || args[:markup_text]
    }
  end

  def settings
    @settings ||= Setting.all_cached
  end
end
