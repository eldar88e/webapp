class CreatePurchases < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases do |t|
      t.integer :status, null: false, default: 0
      t.string  :currency, null: false, default: "TRY"
      t.decimal :exchange_rate,  precision: 10, scale: 2, default: 0
      t.decimal :subtotal,       precision: 10, scale: 2, default: 0
      t.decimal :discount_total, precision: 10, scale: 2, default: 0
      t.decimal :shipping_total, precision: 10, scale: 2, default: 0
      t.decimal :total,          precision: 10, scale: 2, default: 0
      t.datetime :sent_to_supplier_at
      t.datetime :acknowledged_at
      t.datetime :shipped_at
      t.datetime :received_at
      t.datetime :stocked_at
      t.text :notes

      t.timestamps
    end
  end
end
