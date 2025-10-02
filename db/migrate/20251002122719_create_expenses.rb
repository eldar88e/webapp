class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.integer :category, null: false, default: 0
      t.string  :description
      t.integer :amount, null: false, default: 0
      t.decimal :exchange_rate, precision: 12, scale: 2, null: false

      t.references :expenseable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
