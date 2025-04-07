require 'telegram/bot'

module Tg
  class MediaSenderService
    MESSAGE_LIMIT = 4_090

    def initialize(message, id, data)
      @chat_id = id
      @message = message.present? ? escape(message) : nil
      @data    = data
    end

    def self.call(msg, id, data)
      new(msg, id, data).send_message
    end

    def send_message
      return unless bot_ready?

      Telegram::Bot::Client.run(Setting.fetch_value(:tg_token)) do |bot|
        return send_attachment(bot) if @data[:tg_file_id].present? || @data[:file].present?

        send_text(bot) if @message.present?
      end
      @result
    rescue StandardError => e
      Rails.logger.error "Failed to send message to bot: #{e.message}"
      e
    end

    private

    def bot_ready?
      if Setting.fetch_value(:tg_token).present? && @chat_id.present? && (@message.present? || @data.values.any?)
        true
      else
        Rails.logger.error 'Telegram chat ID or bot token not set or empty message or data!'
        false
      end
    end

    def escape(text)
      text.gsub(/\[.*?m/, '').gsub(/([-_\[\]()~>#+=|{}.!])/, '\\\\\1')
    end

    def send_text(bot)
      message_count = (@message.size / MESSAGE_LIMIT) + 1
      message_count.times do
        text_part = next_text_part
        @result   = bot.api.send_message(
          chat_id: @chat_id, text: text_part, parse_mode: 'MarkdownV2', reply_markup: form_markup
        )
      end
    end

    def send_attachment(bot)
      if @data[:tg_file_id].present?
        send_by_file_id(bot)
      elsif @data[:file].present?
        result = send_uploaded_file(bot)
        result.nil? ? raise("Error sending file: #{@data[:file].blob.filename}") : result
      end
    end

    def send_uploaded_file(bot)
      result = nil
      @data[:file].blob.open do |tempfile|
        upload_io = Faraday::UploadIO.new(tempfile.path, @data[:file].blob.content_type)
        result    = send_data(bot, upload_io)
      end
      result
    end

    def send_by_file_id(bot)
      send_data(bot, @data[:tg_file_id])
    end

    def send_data(bot, data)
      if @data[:type] == 'image'
        bot.api.send_photo(
          chat_id: @chat_id, photo: data, caption: @message, parse_mode: 'MarkdownV2', reply_markup: form_markup
        )
      elsif @data[:type] == 'video'
        bot.api.send_video(
          chat_id: @chat_id, video: data, caption: @message, parse_mode: 'MarkdownV2', reply_markup: form_markup
        )
      end
    end

    def form_markup
      return if @data[:markup].nil?

      Tg::MarkupService.call(@data)
    end

    def next_text_part
      part     = @message[0...MESSAGE_LIMIT]
      @message = @message[MESSAGE_LIMIT..] || ''
      part
    end
  end
end
