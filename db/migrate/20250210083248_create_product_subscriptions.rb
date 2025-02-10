class CreateProductSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :product_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
