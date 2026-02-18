class AddScheduledAtToMailings < ActiveRecord::Migration[8.1]
  def change
    add_column :mailings, :scheduled_at, :datetime
  end
end
