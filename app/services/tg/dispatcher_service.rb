module Tg
  class DispatcherService
    MESSAGE_TYPES = %w[text photo sticker video document].freeze

    class << self
      def call(bot, message)
        type = MESSAGE_TYPES.find { |t| message.public_send(t).present? }
        return send("save_#{type}", bot, message) if type

        other_message(bot, message)
      end

      private

      def save_text(bot, message)
        process_message(message)
        send_firs_msg(bot, message.chat.id)
      end

      def save_photo(_bot, message)
        tg_id   = message.chat.id
        file_id = message.photo.last.file_id
        msg_id  = message.message_id
        TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id)
      end

      def save_sticker(_bot, message)
        user = find_user(message.chat.as_json)
        user.messages.create(text: message.sticker.emoji, tg_msg_id: message.message_id)
      end

      def save_video(bot, message)
        tg_id   = message.chat.id
        file_id = message.video.file_id
        msg_id  = message.message_id
        TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id)
        send_admin_video_id(bot, message)
      end

      def save_document(_bot, message)
        tg_id   = message.chat.id
        file_id = message.document.file_id
        msg_id  = message.message_id
        TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id)
      end

      def send_firs_msg(bot, chat_id)
        markup  = Tg::MarkupService.call({ markup: 'first_msg' })
        caption = settings[:preview_msg].to_s.gsub('\\n', "\n")
        if settings[:first_video_id].present?
          bot.api.send_video(chat_id: chat_id, video: settings[:first_video_id], caption: caption, reply_markup: markup)
        else
          bot.api.send_message(chat_id: chat_id, text: caption, reply_markup: markup)
        end
      end

      def send_admin_video_id(bot, message)
        return unless settings[:admin_ids].split(',').include?(message.chat.id.to_s)

        bot.api.send_message(chat_id: message.chat.id, text: "ID видео:\n#{message.video.file_id}")
      end

      def process_message(message)
        chat = message.chat.as_json
        if %(group supergroup).include?(chat['type'])
          return TelegramJob.perform_later(msg: "Группа: `#{chat['title']}`\nID: `#{chat['id']}`")
        end

        user = find_user(chat)
        return if message.text == '/start'

        user.messages.create(text: message.text, tg_msg_id: message.message_id)
      end

      def find_user(chat)
        user = User.find_or_create_by_tg(chat, true)
        unlock_user(user) unless user.started
        user
      end

      def unlock_user(user)
        user.update(started: true, is_blocked: false)
        Rails.logger.info "User #{user.id} started bot"
      end

      def other_message(bot, message)
        TelegramJob.perform_later(msg: "Неизв. тип сообщения от #{message.chat.id}", id: settings[:test_id])
        TelegramJob.perform_later(msg: message.to_json, id: settings[:test_id])
        send_firs_msg(bot, message.chat.id)
      end

      def settings
        Setting.all_cached
      end
    end
  end
end
