module Admin
  class ReviewsController < Admin::ApplicationController
    before_action :set_review, only: %i[edit update destroy]

    def index
      @q_reviews = Review.includes(:user, :product, :photos_attachments).order(created_at: :desc).ransack(params[:q])
      @pagy, @reviews = pagy(@q_reviews.result, items: 20)
    end

    def new
      @review = Review.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить отзыв'),
        turbo_stream.update(:modal_body, partial: '/admin/reviews/form', locals: { review: @review, method: :post })
      ]
    end

    def create
      @review = Review.new(review_params)

      if @review.save
        redirect_to admin_reviews_path, notice: 'Отзыв успешно создан.'
      else
        error_notice(@review.errors.full_messages, :unprocessable_entity)
      end
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактирование отзыва'),
        turbo_stream.update(:modal_body, partial: '/admin/reviews/edit')
      ]
    end

    def update
      if params[:review][:photos].present?
        @review.photos.attach(params[:review][:photos])
      end

      if @review.update(review_params.except(:photos))
        render turbo_stream: [
          turbo_stream.replace(@review, partial: '/admin/reviews/review', locals: { review: @review }),
          success_notice('Отзыв успешно обновлен.')
        ]
      else
        error_notice(@review.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @review.destroy!
      redirect_to admin_reviews_path, status: :see_other, notice: 'Отзыв успешно удален.'
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def review_params
      params.require(:review).permit(:content, :rating, :approved, photos: [])
    end
  end
end
