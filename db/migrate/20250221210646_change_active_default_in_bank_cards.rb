class ChangeActiveDefaultInBankCards < ActiveRecord::Migration[7.2]
  def change
    change_column_default :bank_cards, :active, true
    change_column_null :bank_cards, :active, false, true
  end
end
