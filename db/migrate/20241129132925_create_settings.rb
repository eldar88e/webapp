class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.string :variable
      t.string :value
      t.string :description

      t.timestamps
    end

    add_index :settings, :variable, unique: true
  end
end
