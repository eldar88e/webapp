module Admin
  class MessagesController < Admin::ApplicationController
    def index
      return redirect_to admin_dashboard_path if current_user.id != 2

      @q_messages = Message.includes(:user).order(created_at: :desc).ransack(params[:q])
      @pagy, @messages = pagy(@q_messages.result.joins(:user), items: 20)
    end
  end
end
