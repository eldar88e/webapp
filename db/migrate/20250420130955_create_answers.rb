class CreateAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :answer_option, null: false, foreign_key: true
      t.text :answer_text

      t.timestamps
    end
  end
end
