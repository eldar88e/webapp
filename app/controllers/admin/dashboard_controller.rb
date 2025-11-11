module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!, :authorize_admin_access!

    def index
      return redirect_to new_user_session_path unless user_signed_in?

      redirect_to root_path unless current_user.admin_or_moderator_or_manager?
    end
  end
end
