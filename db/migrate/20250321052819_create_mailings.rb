class CreateMailings < ActiveRecord::Migration[7.2]
  def change
    create_table :mailings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :to, null: false, default: 0
      t.datetime :send_at, null: false
      t.boolean :completed, default: false
      t.text :message, limit: 4000

      t.timestamps
    end
  end
end
