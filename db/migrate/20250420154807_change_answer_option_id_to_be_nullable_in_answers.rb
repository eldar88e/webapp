class ChangeAnswerOptionIdToBeNullableInAnswers < ActiveRecord::Migration[7.2]
  def change
    change_column_null :answers, :answer_option_id, true
  end
end
