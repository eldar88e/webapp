class AddSourceToBonusLogs < ActiveRecord::Migration[7.2]
  def change
    change_table :bonus_logs, bulk: true do |t|
      t.references :source, polymorphic: true, index: true
    end
  end
end
