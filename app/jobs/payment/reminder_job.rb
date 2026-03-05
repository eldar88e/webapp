module Payment
  class ReminderJob < ApplicationJob
    queue_as :default

    def perform(**args)
      Rails.cache.fetch("payment_reminder_#{args[:order_id]}_#{args[:msg_type]}", expires_in: 30.minutes) do
        Payment::ReminderService.call(**args)
      end
    end
  end
end
