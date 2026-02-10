module Payment
  class CheckStatusJob < ApplicationJob
    queue_as :default

    def perform(transaction_id, status)
      Payment::CheckStatusService.call(transaction_id, status)
    end
  end
end
