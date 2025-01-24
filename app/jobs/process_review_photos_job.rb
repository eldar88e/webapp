class ProcessReviewPhotosJob < ApplicationJob
  queue_as :default

  def perform(review)
    review.photos.each do |photo|
      photo.variant(:big).processed
      photo.variant(:thumb).processed
    end
  rescue StandardError => e
    Rails.logger.error "Error processing review photos: #{e.message}"
  end
end
