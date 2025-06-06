module Admin
  class ReviewsController < Admin::ApplicationController
    before_action :set_review, only: %i[edit update destroy]
    before_action :update_photo, only: :update

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
      @review = Review.new(review_params)

      if @review.save
        redirect_to admin_reviews_path, notice: t('controller.reviews.create')
      else
        error_notice(@review.errors.full_messages, :unprocessable_entity)
      end
    end

    def update
      if @review.update(review_params.except(:photos))
        render turbo_stream: [
          turbo_stream.replace(@review, partial: '/admin/reviews/review', locals: { review: @review }),
          success_notice(t('controller.reviews.update'))
        ]
      else
        error_notice(@review.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @review.destroy!
      redirect_to admin_reviews_path, status: :see_other, notice: t('controller.reviews.destroy')
    end

    private

    def update_photo
      @review.photos.attach(params[:review][:photos]) if params[:review][:photos].present?
    end

    def set_review
      @review = Review.find(params[:id])
    end

    def review_params
      params.require(:review).permit(:content, :product_id, :rating, :approved, :user_id, photos: [])
    end
  end
end
