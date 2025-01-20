module ReviewsHelper
  def percentages
    reviews = @product.reviews.approved
    return [] if reviews.blank?

    total_reviews = reviews.count
    rating_counts = reviews.group(:rating).count
    (1..5).map { |rating| { rating: rating, percentage: (rating_counts[rating] || 0) * 100.0 / total_reviews } }
  end
end
