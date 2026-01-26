class AddCommentsCountToTasks < ActiveRecord::Migration[7.2]
  class MigrationTask < ApplicationRecord
    self.table_name = "tasks"
  end

  def up
    add_column :tasks, :comments_count, :integer, default: 0, null: false

    MigrationTask.reset_column_information
    MigrationTask.find_each { |task| MigrationTask.reset_counters(task.id, :comments) }
  end

  def down
    remove_column :tasks, :comments_count
  end
end
