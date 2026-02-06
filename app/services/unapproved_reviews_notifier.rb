class UnapprovedReviewsNotifier
  def self.call
    count = Review.where(approved: false).count
    return if count.zero?

    message = "⚠️ Непроверенных отзывов: #{count}"
    markup  = { markup_url: 'admin/reviews', markup_text: 'Проверить отзывы' }
    TelegramService.call(message, Setting.fetch_value(:admin_ids), **markup)
  end
end
