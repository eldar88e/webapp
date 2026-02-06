class UnapprovedReviewsNotifierJob < ApplicationJob
  def perform
    UnapprovedReviewsNotifier.call
  end
end
