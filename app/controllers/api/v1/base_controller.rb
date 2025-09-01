module Api
  module V1
    class BaseController < ActionController::API
      private

      def authenticate_with_token!
        return if ENV.fetch('JWT_SECRET') == request.headers['Authorization']

        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
