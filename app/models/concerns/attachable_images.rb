module AttachableImages
  extend ActiveSupport::Concern

  included do
    # ...
  end

  def attach_file(attachment, file)
    return if file.blank?

    attachment.attach(file)
    GenerateImageVariantsJob.perform_later(attachment.blob.id) if Rails.env.production? && attachment.attached?
  end
end
