module Admin
  class BonusLogsController < ApplicationController
    def index
      bonus_logs = BonusLog.order(:created_at).includes(:user)
      @pagy, @bonus_logs = pagy(bonus_logs)
    end
  end
end
