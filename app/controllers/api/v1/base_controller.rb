module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :check_authenticate_user!, :product_search
      before_action :authenticate_with_token!

      private

      def authenticate_with_token!
        token = request.headers['Authorization'].to_s.split(' ').last
        return if token.present? && ENV.fetch('JWT_SECRET') == token

        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
