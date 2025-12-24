module Admin
  class QuestionsController < Admin::ApplicationController
    include Admin::ResourceConcerns

    def index
      @q_resources      = Question.order(:created_at).ransack(params[:q])
      @pagy, @resources = pagy(@q_resources.result)
    end

    private

    def question_params
      # rubocop:disable Rails/StrongParametersExpect
      params.require(:question).permit(:text, answer_options_attributes: %i[id question_id text _destroy])
      # rubocop:enable Rails/StrongParametersExpect
    end
  end
end
