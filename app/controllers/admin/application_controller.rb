module Admin
  class ApplicationController < ActionController::Base
    include Pundit::Authorization
    include MainConcerns
    include Pagy::Backend

    before_action :authenticate_user!, :authorize_admin_access!

    layout 'admin'

    rescue_from Pundit::NotAuthorizedError, with: :redirect_to_telegram

    private

    def authorize_admin_access!
      authorize %i[admin base], :admin_access?
    end
  end
end
