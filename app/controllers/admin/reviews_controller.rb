module Admin
  class ReviewsController < Admin::ApplicationController
    before_action :set_review, only: %i[edit update destroy]

    def index
      @q_reviews = Review.includes(:user, :product, :photos_attachments).order(created_at: :desc).ransack(params[:q])
      @pagy, @reviews = pagy(@q_reviews.result)
    end

    def new
      @review = Review.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить отзыв'),
        turbo_stream.update(:modal_body, partial: '/admin/reviews/form', locals: { review: @review, method: :post })
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактирование отзыва'),
        turbo_stream.update(:modal_body, partial: '/admin/reviews/edit')
      ]
    end

    def create
      @review = Review.new(review_params.except(:photos))

      if @review.save
        @review.attach_photos(review_params[:photos], notify: true)
        redirect_to admin_reviews_path, notice: t('controller.reviews.create')
      else
        error_notice @review.errors.full_messages
      end
    end

    def update
      if @review.update(review_params.except(:photos))
        @review.attach_photos(review_params[:photos])
        render turbo_stream: [
          turbo_stream.replace(@review, partial: '/admin/reviews/review', locals: { review: @review }),
          success_notice(t('controller.reviews.update'))
        ]
      else
        error_notice @review.errors.full_messages
      end
    end

    def destroy
      @review.destroy!
      redirect_to admin_reviews_path, status: :see_other, notice: t('controller.reviews.destroy')
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def review_params
      params.expect(review: [:content, :product_id, :rating, :approved, :user_id, { photos: [] }])
    end
  end
end
