class ApplicationController < ActionController::Base
  STRONG_USER_PARAMS = %i[first_name middle_name last_name phone_number email address street home postal_code].freeze

  include MainConcerns
  include Pagy::Backend

  before_action :check_authenticate_user!
  skip_before_action :check_authenticate_user!, if: :devise_confirmation_controller?
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  helper_method :available_products, :favorite_ids, :cart_items, :current_cart, :product_search

  private

  def after_sign_in_path_for(resource)
    resource.admin_or_moderator_or_manager? ? admin_path : root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def devise_confirmation_controller?
    is_a?(DeviseController) && %w[sessions confirmations passwords registrations].include?(controller_name)
  end

  def product_search
    @product_search ||= available_products.ransack(params[:q])
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
    if current_user
      error_register if !current_user.started? || current_user.is_blocked?
    else
      render 'auth/login', layout: 'login'
    end
  end

  def user_params
    keys = STRONG_USER_PARAMS + %i[apartment build]
    params.require(:user).permit(keys)
  end

  def filtered_params
    user_params.to_h.compact_blank
  end

  def required_fields_filled?
    STRONG_USER_PARAMS.all? { |key| filtered_params[key].present? }
  end

  def error_register
    UserCheckerJob.perform_later(current_user.id)
    render 'auth/error_register'
  end
end
