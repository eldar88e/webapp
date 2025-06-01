module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :check_authenticate_user!, :product_search
      before_action :authenticate_with_token!

      private

      def authenticate_with_token!
        return if ENV.fetch('JWT_SECRET') == request.headers['Authorization']

        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
