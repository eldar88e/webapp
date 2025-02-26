class AddBankCardToOrders < ActiveRecord::Migration[7.2]
  def change
    add_reference :orders, :bank_card, foreign_key: true
  end
end
