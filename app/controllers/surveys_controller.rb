class SurveysController < ApplicationController
  def index
    return redirect_to root_path, notice: t('.success') if current_user.answers.size == 3

    @questions = Question.includes([:answer_options]).order(:created_at)
  end

  def add_answers
    save_answers
    current_user.update(email: params[:answer][:email]) if params[:answer][:email].present?

    redirect_to root_path, notice: t('.success')
  end

  private

  def save_answers
    params[:answer].as_json.each do |key, value|
      next unless key.include? 'question'

      question_id = key.split('_').second
      answer      = key.include?('options') ? { answer_option_id: value.to_i } : { answer_text: value }
      current_user.answers.create!({ question_id: question_id }.merge(answer))
    end
  end
end
