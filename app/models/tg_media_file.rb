class TgMediaFile < ApplicationRecord
  has_one_attached :attachment, dependent: :purge

  validates :file_hash, presence: true
  validates :file_hash, uniqueness: true

  def self.fetch_or_create_by_hash(file_hash:, file_type:, original_filename:, attachment: nil, file_id: nil)
    media = find_or_create_by!(file_hash: file_hash) do |media|
      media.file_type         = file_type
      media.original_filename = original_filename
      media.file_id           = file_id if file_id.present?
    end
    attach_file(attachment, media) if attachment.present? && !media.attachment.attached?
    media
  end

  def image?
    file_type.start_with?('image')
  end

  def video?
    file_type.start_with?('video')
  end

  def self.attach_file(attachment, media)
    if attachment.is_a?(ActiveStorage::Blob)
      media.attachment.attach(attachment)
    elsif attachment.is_a?(ActionDispatch::Http::UploadedFile)
      media.attachment = attachment
      media.save!
    end
    return unless media.attachment.attached? && Rails.env.production?

    GenerateImageVariantsJob.perform_later(media.attachment.blob.id)
  end
end
