class CreateBankCards < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_cards do |t|
      t.string :fio
      t.string :number
      t.boolean :active

      t.timestamps
    end
  end
end
