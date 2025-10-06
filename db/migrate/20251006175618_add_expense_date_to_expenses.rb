class AddExpenseDateToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :expense_date, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    add_index  :expenses, :expense_date
  end
end
