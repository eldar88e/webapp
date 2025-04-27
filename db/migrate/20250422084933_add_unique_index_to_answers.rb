class AddUniqueIndexToAnswers < ActiveRecord::Migration[7.2]
  def change
    add_index :answers, [:user_id, :question_id], unique: true
  end
end
