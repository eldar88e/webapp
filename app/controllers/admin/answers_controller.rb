module Admin
  class AnswersController < Admin::ApplicationController
    def index
      @pagy, @answers = pagy(Answer.includes(:user, :question, :answer_option).order(:created_at))
    end
  end
end
