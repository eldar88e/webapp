class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.text :text
      t.bigint :tg_id

      t.timestamps
    end
  end
end
