module Admin
  class ApplicationController < ActionController::Base
    include Pundit::Authorization
    include MainConcerns
    include Pagy::Backend

    before_action :authenticate_user!, :authorize_admin_access!
    before_action :set_search_params, if: -> { action_name == 'index' }

    layout 'admin'

    rescue_from Pundit::NotAuthorizedError, with: :redirect_to_telegram

    private

    def set_search_params
      set_session_params
      return unless session["#{controller_name}_q"].present? && params[:q].blank? && params[:page].present?

      params[:q] = session["#{controller_name}_q"]
    end

    def set_session_params
      session["#{controller_name}_q"] = params[:q] if params[:q].present?
    end

    def authorize_admin_access!
      authorize %i[admin base], :admin_access?
    end
  end
end
