module Payment
  class ReminderJob < ApplicationJob
    queue_as :default

    def perform(**args)
      Payment::ReminderService.call(**args)
    end
  end
end
