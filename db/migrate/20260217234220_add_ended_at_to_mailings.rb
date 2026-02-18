class AddEndedAtToMailings < ActiveRecord::Migration[8.1]
  def change
    add_column :mailings, :ended_at, :datetime
  end
end
