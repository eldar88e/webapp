class AttachmentService
  class << self
    def call(attachment)
      tg_media_file = find_or_create_tg_media_file(attachment)
      return {} if tg_media_file.nil?

      data        = form_tg_file(tg_media_file)
      data[:type] = tg_media_file.file_type.split('/').at(0) if tg_media_file.present?
      data
    end

    private

    def find_or_create_tg_media_file(attachment)
      return if attachment.blank?

      file_hash = Digest::MD5.file(attachment).hexdigest
      TgMediaFile.find_or_create_by!(file_hash: file_hash) { |media| form_media_attr(media, attachment) }
    end

    def form_tg_file(tg_media_file)
      tg_media_file.file_id.present? ? { tg_file_id: tg_media_file.file_id } : { media_id: tg_media_file.id }
    end

    def form_media_attr(media, attachment)
      media.file_type         = attachment.content_type
      media.original_filename = attachment.original_filename
      media.attachment        = attachment
    end
  end
end
