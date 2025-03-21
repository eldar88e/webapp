class RenameToColumnInMailings < ActiveRecord::Migration[7.2]
  def change
    rename_column :mailings, :to, :target
  end
end
