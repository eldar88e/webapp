module Admin
  class SupportsController < ApplicationController
    before_action :set_question, only: %i[edit update destroy]

    def index
      @pagy, @questions = pagy SupportEntry.order(:question)
    end

    def new
      @questions = SupportEntry.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить вопрос'),
        turbo_stream.update(:modal_body, partial: '/admin/supports/form', locals: { method: :post })
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать вопрос'),
        turbo_stream.update(:modal_body, partial: '/admin/supports/form', locals: { method: :patch })
      ]
    end

    def create
      @question = SupportEntry.new(question: params[:question], answer: params[:answer])

      if @question.save
        redirect_to admin_supports_path, notice: t('.create')
      else
        error_notice(@question.errors.full_messages)
      end
    end

    def update
      if @question.update(question_params)
        redirect_to admin_supports_path, notice: t('.update')
      else
        error_notice(@question.errors.full_messages)
      end
    end

    def destroy
      @question.destroy!
      redirect_to admin_supports_path, status: :see_other, notice: t('.destroy')
    end

    private

    def set_question
      @question = SupportEntry.find(params[:id])
    end

    def question_params
      params.require(:support_entry).permit(:question, :answer)
    end
  end
end
