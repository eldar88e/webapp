class AddNameToBankCards < ActiveRecord::Migration[7.2]
  def change
    add_column :bank_cards, :name, :string, null: false
  end
end
