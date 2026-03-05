class AttachmentService
  class << self
    def call(attachment)
      return {} if attachment.blank?

      tg_media_file = find_or_create_tg_media_file(attachment)
      Tg::MessageService.build_data(tg_media_file)
    end

    private

    def find_or_create_tg_media_file(attachment)
      file_hash = Digest::MD5.file(attachment).hexdigest
      TgMediaFile.fetch_or_create_by_hash(
        file_hash: file_hash,
        file_type: attachment.content_type,
        original_filename: attachment.original_filename,
        attachment: attachment
      )
    end
  end
end
