module Tg
  class FileService
    def self.update_file_id(message)
      return if message.data['tg_file_id'].present? || message.data['media_id'].blank?

      sleep 3
      message.data['tg_file_id'] = TgMediaFile.find_by(id: message.data['media_id'])&.file_id
      message.save
    end
  end
end
