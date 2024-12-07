class ChangeTgIdToBigintAndNotNull < ActiveRecord::Migration[7.2]
  def change
    change_column :users, :tg_id, :bigint

    change_column_null :users, :tg_id, false
  end
end
