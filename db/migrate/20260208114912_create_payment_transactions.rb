class CreatePaymentTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_transactions do |t|
      t.references :order, null: false, foreign_key: true

      t.string :object_token
      t.integer :status, default: 0, null: false
      t.integer :payment_method,default: 1, null: false

      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string  :currency, default: "₽", null: false
      t.decimal :amount_transfer, precision: 12, scale: 2, default: 0

      t.string :bank_name
      t.string :card_people
      t.string :card_number

      t.datetime :initialized_at
      t.datetime :paid_at
      t.datetime :checking_at
      t.datetime :approved_at
      t.datetime :cancelled_at
      t.datetime :overdue_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :payment_transactions, :object_token, unique: true
    add_index :payment_transactions, :status
  end
end
