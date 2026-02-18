module Tg
  class DispatcherService
    MESSAGE_TYPES = %w[text photo sticker video document].freeze

    class << self
      def call(bot, message)
        type = MESSAGE_TYPES.find { |t| message.public_send(t).present? }
        return handle_admin_reply(bot, message, type) if admin_reply?(message)
        return send("save_#{type}", bot, message) if type

        other_message(bot, message)
      end

      private

      def admin?(tg_id)
        settings[:admin_ids].to_s.split(',').include?(tg_id.to_s)
      end

      def admin_reply?(message)
        admin?(message.chat.id) &&
          message.respond_to?(:reply_to_message) &&
          message.reply_to_message.present? # &&
        # message.reply_to_message.text&.include?('Входящее сообщение')
      end

      def handle_admin_reply(_bot, message, type)
        Rails.logger.error '*' * 70
        Rails.logger.error "Admin reply: #{message.reply_to_message}"
        Rails.logger.error "Admin reply msg_id: #{message.reply_to_message.message_id}"
        Rails.logger.error '=' * 70
        user = find_reply_user(message.reply_to_message)
        return unless user

        admin_user = User.find_by(tg_id: message.chat.id)

        case type
        when 'text'
          user.messages.create(text: message.text, is_incoming: false, manager_id: admin_user&.id)
        when 'photo'
          forward_admin_file(user, admin_user, message.photo.last.file_id, message.caption)
        when 'video'
          forward_admin_file(user, admin_user, message.video.file_id, message.caption)
        when 'document'
          forward_admin_file(user, admin_user, message.document.file_id, message.caption)
        when 'sticker'
          user.messages.create(text: message.sticker.emoji, is_incoming: false, manager_id: admin_user&.id)
        end
      end

      def find_reply_user(replied_msg)
        return unless replied_msg

        Message.find_by(tg_msg_id: replied_msg.message_id)&.user
      end

      def forward_admin_file(user, admin_user, file_id, caption)
        TgFileDownloaderJob.perform_later(
          tg_id: user.tg_id, file_id: file_id, msg: caption,
          is_outgoing: true, manager_id: admin_user&.id
        )
      end

      def save_text(bot, message)
        process_message(bot, message)
        # send_firs_msg(bot, message.chat.id)
      end

      def save_photo(_bot, message)
        tg_id   = message.chat.id
        file_id = message.photo.last.file_id
        msg_id  = message.message_id
        TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id,
                                          reply_to_id: find_reply_to_id(message))
      end

      def save_sticker(_bot, message)
        user = find_user(message.chat.as_json)
        user.messages.create(text: message.sticker.emoji, tg_msg_id: message.message_id,
                             reply_to_id: find_reply_to_id(message))
      end

      def save_video(bot, message)
        tg_id   = message.chat.id
        file_id = message.video.file_id
        msg_id  = message.message_id
        TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id,
                                          reply_to_id: find_reply_to_id(message))
        send_admin_video_id(bot, message)
      end

      def save_document(_bot, message)
        tg_id   = message.chat.id
        file_id = message.document.file_id
        msg_id  = message.message_id
        TgFileDownloaderJob.perform_later(tg_id: tg_id, file_id: file_id, msg: message.caption, msg_id: msg_id,
                                          reply_to_id: find_reply_to_id(message))
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

      def process_message(bot, message)
        chat = message.chat.as_json
        return send_admin(chat, message.text) if %w[group supergroup].include?(chat['type'])

        user = find_user(chat)
        send_firs_msg(bot, message.chat.id) if message.text == '/start'

        user.messages.create(text: message.text, tg_msg_id: message.message_id,
                             reply_to_id: find_reply_to_id(message))
      end

      def send_admin(chat, message)
        msg = "Группа: `#{chat['title']}`\nID: `#{chat['id']}`\n\n#{message}"
        TelegramJob.perform_later(msg: msg, id: settings[:admin_ids])
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

      def find_reply_to_id(message)
        return unless message.respond_to?(:reply_to_message) && message.reply_to_message.present?

        Message.find_by(tg_msg_id: message.reply_to_message.message_id, tg_id: message.chat.id)&.id
      end

      def settings
        Setting.all_cached
      end
    end
  end
end
