class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title
      t.integer :priority
      t.references :user, null: false, foreign_key: true
      t.references :assignee, null: false, foreign_key: { to_table: :users }
      t.date :start_date
      t.date :due_date
      t.integer :stage
      t.integer :category
      t.integer :task_type
      t.integer :deadline_notification_days
      t.integer :position

      t.timestamps
    end
  end
end
