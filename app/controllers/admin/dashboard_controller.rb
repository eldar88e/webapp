module Admin
  class DashboardController < Admin::ApplicationController
    skip_before_action :authenticate_user!

    def login
      return redirect_to admin_dashboard_path if current_user

      render layout: 'admin_authorize'
    end

    def index
      redirect_to admin_login_path unless user_signed_in?
    end
  end
end
