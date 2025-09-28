class ChangeDefaultPositionInTasks < ActiveRecord::Migration[7.2]
  def change
    change_column_default :tasks, :position, from: nil, to: 0
    # change_column_null :tasks, :position, false, 0
  end
end
