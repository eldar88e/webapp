class ApplicationController < ActionController::Base
  include MainConcerns
  before_action :check_authenticate_user!, :product_search
  skip_before_action :check_authenticate_user!, if: :devise_confirmation_controller?
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  helper_method :available_products, :favorite_ids, :cart_items, :current_cart

  private

  # def after_sign_in_path_for(user)
  #   user.admin_or_moderator_or_manager? ? admin_path : root_path
  # end

  def devise_confirmation_controller?
    is_a?(Devise::ConfirmationsController)
  end

  def product_search
    @q_products = available_products.ransack(params[:q])
  end

  def cart_items
    @cart_items ||= current_cart.cart_items
  end

  def favorite_ids
    @favorite_ids ||= current_user.favorite_products.pluck(:product_id).to_set
  end

  def current_cart
    @current_cart ||= current_user.cart
  end

  def available_products
    product_id = params[:category_id].presence || Setting.fetch_value(:default_product_id)
    parent     = Product.find_by(id: product_id)
    if parent
      parent.children.available.order(stock_quantity: :desc, created_at: :desc).includes(:image_attachment)
    else
      Product.none
    end
  end

  def check_authenticate_user!
    redirect_to_telegram unless current_user
  end

  def user_params
    keys = %i[first_name middle_name last_name phone_number email address street home apartment postal_code build]
    params.require(:user).permit(keys)
  end

  def filtered_params
    user_params.to_h.compact_blank
  end

  def required_fields_filled?
    filtered_params.except(:apartment, :build).values.size >= 8
  end
end
