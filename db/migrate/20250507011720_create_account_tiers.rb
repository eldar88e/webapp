class CreateAccountTiers < ActiveRecord::Migration[7.2]
  def change
    create_table :account_tiers do |t|
      t.string :tier_name, null: false  # Название уровня
      t.integer :order_threshold, null: false, default: 0  # Порог по количеству заказов
      t.integer :bonus_percentage, null: false, default: 0  # Процент бонуса для этой градации
      t.integer :order_min_amount, null: false, default: 0  # Порог по сумме заказа

      t.timestamps
    end

    add_index :account_tiers, :tier_name, unique: true
  end
end
