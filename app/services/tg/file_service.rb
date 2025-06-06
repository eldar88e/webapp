module Tg
  class FileService
    def self.update_file_id(message)
      return unless message[:data][:media_id] && message[:data][:tg_file_id].blank?

      tg_media_file = TgMediaFile.find_by(id: message[:data][:media_id])
      return if tg_media_file&.file_id.blank?

      message[:data][:tg_file_id] = tg_media_file.file_id
      message.save
    end
  end
end
