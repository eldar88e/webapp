class ApplicationController < ActionController::Base
  before_action :check_authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  def redirect_to_telegram
    redirect_to "https://t.me/#{settings[:tg_main_bot]}", allow_other_host: true
  end

  private

  def available_products
    @products = Product.includes(:image_attachment).available.all
  end

  def error_notice(msg, status = :unprocessable_entity)
    render turbo_stream: send_notice(msg, 'danger'), status:
  end

  def success_notice(msg)
    send_notice(msg, 'success')
  end

  def send_notice(msg, key)
    turbo_stream.append(:notices, partial: '/notices/notice', locals: { notices: msg, key: })
  end

  def check_authenticate_user!
    redirect_to_telegram unless current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :middle_name, :last_name, :phone_number,
                                 :address, :street, :home, :postal_code, :apartment, :build)
  end

  def filtered_params
    user_params.to_h.reject { |_key, value| value.blank? }
  end

  def required_fields_filled?
    filtered_params.except(:apartment, :build).values.compact_blank.size >= 8
  end

  def settings
    Rails.cache.fetch(:settings, expires_in: 6.hours) do
      Setting.pluck(:variable, :value).to_h.transform_keys(&:to_sym)
    end
  end

  helper_method :settings
end
