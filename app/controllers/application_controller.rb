class ApplicationController < ActionController::Base
  include MainConcerns
  before_action :check_authenticate_user!, :check_started_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  private

  def available_products
    product_id   = params[:category_id].presence || Setting.fetch_value(:default_product_id)
    raw_products = Product.find_by(id: product_id)
    @products    = raw_products.present? ? raw_products.children.includes(:image_attachment).available : []
  end

  def check_authenticate_user!
    redirect_to_telegram unless current_user
  end

  def check_started_user!
    redirect_to '/error-register' if current_user && (current_user.started.blank? || current_user.is_blocked.present?)
  end

  def user_params
    params.require(:user).permit(:first_name, :middle_name, :last_name, :phone_number,
                                 :address, :street, :home, :postal_code, :apartment, :build)
  end

  def filtered_params
    user_params.to_h.compact_blank
  end

  def required_fields_filled?
    filtered_params.except(:apartment, :build).values.size >= 8
  end
end
