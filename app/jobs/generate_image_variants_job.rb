class GenerateImageVariantsJob < ApplicationJob
  queue_as :default

  S3_CONFIG = { endpoint: ENV.fetch('BEGET_ENDPOINT'), region: 'us-east-1',
                access_key_id: ENV.fetch('BEGET_ACCESS'), secret_access_key: ENV.fetch('BEGET_SECRET'),
                force_path_style: true }.freeze
  PARAMS = { metadata_directive: 'REPLACE', cache_control: 'public, max-age=31536000, immutable' }.freeze

  def perform(blob_ids)
    return if blob_ids.blank?

    blobs = ActiveStorage::Blob.where(id: blob_ids)
    process_variants(blobs)
    update_cache_control(blobs) unless Rails.env.test?
  end

  private

  def process_variants(blobs)
    blobs.each do |blob|
      blob.attachments.each do |attachment|
        attachment.variant(:thumb).processed
        attachment.variant(:medium).processed
        attachment.variant(:big).processed
      end
    end
  end

  def update_cache_control(blobs)
    s3     = Aws::S3::Client.new(S3_CONFIG)
    bucket = ENV.fetch('BEGET_BUCKET')

    blobs.each do |blob|
      key          = blob.key
      meta         = s3.head_object(bucket: bucket, key: key)
      content_type = meta.content_type

      s3.copy_object(bucket: bucket, key: key, copy_source: "#{bucket}/#{key}", content_type: content_type, **PARAMS)
    rescue StandardError => e
      Rails.logger.error "Failed to update cache control for #{key}: #{e.message}"
    end
  end
end
