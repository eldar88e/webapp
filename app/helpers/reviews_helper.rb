module ReviewsHelper
  def percentages
    total_reviews = @product.reviews.count
    rating_counts = @product.reviews.group(:rating).count
    (1..5).map { |rating| { rating: rating, percentage: (rating_counts[rating] || 0) * 100.0 / total_reviews } }
  end
end
