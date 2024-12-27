module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :authorize_admin_access!

    def login
      return redirect_to admin_path if current_user

      render layout: 'admin_authorize'
    end

    def index
      return redirect_to admin_login_path unless user_signed_in?

      user_not_authorized unless current_user.admin_or_moderator_or_manager?
    end
  end
end
