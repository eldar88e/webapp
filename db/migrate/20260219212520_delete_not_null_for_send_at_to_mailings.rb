class DeleteNotNullForSendAtToMailings < ActiveRecord::Migration[8.1]
  def change
    change_column_null :mailings, :send_at, true
    change_column_null :mailings, :scheduled_at, false
  end
end
