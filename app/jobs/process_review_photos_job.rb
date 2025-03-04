class ProcessReviewPhotosJob < ApplicationJob
  queue_as :default

  def perform(review_id)
    review = Review.find_by(id: review_id.to_i)
    return unless review

    review.photos.each do |photo|
      photo.variant(:big).processed
      photo.variant(:thumb).processed
    end
  rescue StandardError => e
    Rails.logger.error "Error processing review photos: #{e.message}"
  end
end
