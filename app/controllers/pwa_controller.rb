class PwaController < ApplicationController
  skip_before_action :check_authenticate_user!
  skip_forgery_protection
  layout false, except: :offline

  def service_worker
    return render js: 'console.log("SW for dev mode.");'.html_safe if Rails.env.development?

    expires_now
    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    render template: 'pwa/service_worker', formats: :js, content_type: 'application/javascript'
  end

  def manifest
    expires_now
    response.headers['Cache-Control'] = 'no-store'
    render template: 'pwa/manifest'
  end

  def offline
    render :offline
  end
end
