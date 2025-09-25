class RemoveDuplicateIndexFromAnswers < ActiveRecord::Migration[7.2]
  def change
    remove_index :answers, name: "index_answers_on_user_id"
  end
end
