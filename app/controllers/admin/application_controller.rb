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
      session["#{controller_name}_q"] = params[:q] if params[:q].present?
      params[:q] = session["#{controller_name}_q"] if params[:q].blank?
    end

    def authorize_admin_access!
      authorize %i[admin base], :admin_access?
    end
  end
end
