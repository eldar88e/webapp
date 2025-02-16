class ChangeStartedInUsers < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :started, false
  end
end
