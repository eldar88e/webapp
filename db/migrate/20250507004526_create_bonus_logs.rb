class CreateBonusLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :bonus_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :bonus_amount
      t.string :reason

      t.timestamps
    end
  end
end
