class AttachmentService
  class << self
    def call(attachment)
      return {} if attachment.blank?

      tg_media_file = find_or_create_tg_media_file(attachment)
      # data          = form_tg_file(tg_media_file)
      # data[:type]   = tg_media_file.file_type.split('/').at(0) if tg_media_file.present?
      # data
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

    # def form_tg_file(tg_media_file)
    #   tg_media_file.file_id.present? ? { tg_file_id: tg_media_file.file_id } : { media_id: tg_media_file.id }
    # end
  end
end
