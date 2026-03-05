class PushSubscriptionsController < ApplicationController
  def create
    current_user.push_subscriptions.find_or_create_by!(endpoint: params[:endpoint]) do |s|
      s.p256dh = params.dig(:keys, :p256dh)
      s.auth   = params.dig(:keys, :auth)
    end
    head :ok
  end

  def destroy
    current_user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy
    head :ok
  end
end
