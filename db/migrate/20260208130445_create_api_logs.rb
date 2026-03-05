class CreateApiLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :api_logs do |t|
      t.references :loggable, polymorphic: true, index: true

      t.string :action
      t.string :http_method
      t.string :url
      t.jsonb  :request_headers, default: {}
      t.jsonb  :request_body, default: {}

      t.integer :response_status        # 200, 400, 500
      t.jsonb   :response_headers, default: {}
      t.jsonb   :response_body, default: {}

      # META
      t.string  :service_name           # payment_gateway, sms_provider
      t.string  :direction, default: "outgoing"  # outgoing (you → API), incoming (webhook)
      t.float   :duration_ms
      t.boolean :success, default: false
      t.jsonb :error_message, default: {}

      t.datetime :created_at, null: false
    end

    add_index :api_logs, :service_name
    add_index :api_logs, :action
    add_index :api_logs, :created_at
    add_index :api_logs, :success
  end
end
