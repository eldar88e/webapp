class ApplicationController < ActionController::Base
  include MainConcerns
  before_action :check_authenticate_user!, :check_started_user!
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  private

  def available_products
    product_id = params[:category_id].presence || Setting.fetch_value(:default_product_id)
    parent     = Product.find_by(id: product_id)

    return @products = Product.none if parent.blank?

    @products = parent.children
                      .includes(:image_attachment)
                      .available
                      .order(stock_quantity: :desc, created_at: :desc)
  end

  def check_authenticate_user!
    redirect_to_telegram unless current_user
  end

  def check_started_user!
    redirect_to '/error-register' if current_user && (current_user.started.blank? || current_user.is_blocked.present?)
  end

  def user_params
    keys = %i[first_name middle_name last_name phone_number address street home apartment postal_code build]
    params.require(:user).permit(keys)
  end

  def filtered_params
    user_params.to_h.compact_blank
  end

  def required_fields_filled?
    filtered_params.except(:apartment, :build).values.size >= 8
  end
end
