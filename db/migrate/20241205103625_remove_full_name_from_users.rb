class RemoveFullNameFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :full_name, :string
  end
end
