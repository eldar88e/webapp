class GenerateImageVariantsJob < ApplicationJob
  queue_as :default

  PROCESS_VARIANTS = %w[Review].freeze
  VARIANT_NAMES    = %i[thumb big].freeze
  BUCKET           = ENV.fetch('BEGET_BUCKET').freeze
  S3_CONFIG = {
    endpoint: ENV.fetch('BEGET_ENDPOINT'),
    region: 'us-east-1',
    access_key_id: ENV.fetch('BEGET_ACCESS'),
    secret_access_key: ENV.fetch('BEGET_SECRET'),
    force_path_style: true
  }.freeze
  PARAMS = {
    metadata_directive: 'REPLACE',
    cache_control: 'public, max-age=31536000, immutable'
  }.freeze

  def perform(blob_ids)
    return if blob_ids.blank?

    blobs     = ActiveStorage::Blob.where(id: blob_ids)
    s3_client = Aws::S3::Client.new(S3_CONFIG)
    process_variants(blobs, s3_client)
    update_cache_control(blobs, s3_client)
  end

  private

  def process_variants(blobs, s3_client)
    return unless PROCESS_VARIANTS.include? blobs.first.attachments.first.record_type

    blobs.each do |blob|
      blob.attachments.each do |attachment|
        VARIANT_NAMES.each do |variant_name|
          variant = attachment.variant(variant_name).processed
          copy_object(s3_client, variant.key, variant.content_type)
        end
      end
    end
  end

  def update_cache_control(blobs, s3_client)
    blobs.each { |blob| copy_object(s3_client, blob.key, blob.content_type) }
  end

  def copy_object(s3_client, key, content_type)
    s3_client.copy_object(
      bucket: BUCKET,
      key: key,
      copy_source: "#{BUCKET}/#{key}",
      content_type: content_type,
      **PARAMS
    )
  rescue StandardError => e
    Rails.logger.error "Failed to update cache control for #{key}: #{e.message}"
  end
end
