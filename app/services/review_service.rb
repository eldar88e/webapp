class ReviewService
  def self.form_info(product)
    Rails.cache.fetch("reviews_info_#{product.id}", expires_in: 1.hour) do
      reviews = product.reviews.approved
      return { average_rating: 0, count: 0, percentages: [] } if reviews.blank?

      {
        average_rating: reviews.average(:rating).round(1),
        count: reviews.size,
        percentages: form_percentages(reviews)
      }
    end
  end

  private

  def form_percentages(reviews)
    total_reviews = reviews.count
    rating_counts = reviews.group(:rating).count
    (1..5).map { |rating| { rating: rating, percentage: (rating_counts[rating] || 0) * 100.0 / total_reviews } }
  end
end
