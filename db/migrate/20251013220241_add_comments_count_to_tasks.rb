class AddCommentsCountToTasks < ActiveRecord::Migration[7.2]
  def up
    add_column :tasks, :comments_count, :integer, default: 0, null: false
    Task.find_each { |task| Task.reset_counters(task.id, :comments) }
  end

  def down
    remove_column :tasks, :comments_count
  end
end
