class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
         :confirmable

  enum :role, { user: 0, manager: 1, moderator: 2, admin: 3 }

  has_many :orders, dependent: :destroy
  has_many :messages, primary_key: :tg_id, foreign_key: :tg_id, inverse_of: :user, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :product_subscriptions, dependent: :destroy
  has_many :subscribed_products, through: :product_subscriptions, source: :product
  has_many :mailings, dependent: :destroy

  validates :tg_id, presence: true, uniqueness: true
  validates :email, 'valid_email_2/email': { strict_mx: true, disposable: true }
  validates :postal_code, numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: 100_000,
                                          less_than_or_equal_to: 999_999 }

  before_update :reset_confirmation_if_email_changed, if: :will_save_change_to_email?
  after_update :resend_confirmation_email, if: :saved_change_to_email?

  def admin?
    role == 'admin'
  end

  def moderator?
    role == 'moderator'
  end

  def manager?
    role == 'manager'
  end

  def admin_or_moderator_or_manager?
    moderator? || admin? || manager?
  end

  def cart
    super || create_cart
  end

  def full_name
    "#{middle_name} #{first_name} #{last_name}"
  end

  def user_name
    return "@#{username}" if username.present?

    full_name.presence || "User #{id}"
  end

  def full_address
    return if address.blank?

    result = "#{address}, #{street}, дом #{home}"
    result += ", Квартира #{apartment}" if apartment.present?
    result += ", Корпус #{build}" if build.present?
    result
  end

  def self.repeat_order_rate(start_date, end_date)
    total_customers = joins(:orders)
                      .where(orders: { created_at: start_date..end_date, status: :shipped })
                      .distinct.count

    return [0, 0] if total_customers.zero?

    repeat_customers = joins(:orders)
                       .where(orders: { created_at: start_date..end_date, status: :shipped })
                       .group('users.id')
                       .having('COUNT(orders.id) > 1')
                       .count.size
    [repeat_customers.to_f, total_customers.to_f] # .round(2)
  end

  def self.registered_count_grouped_by_period(start_date, end_date, period)
    where(created_at: start_date..end_date).group(period).count
  end

  def self.find_or_create_by_tg(tg_user, started)
    current_user = find_or_create_by(tg_id: tg_user['id']) do |user|
      assign_user_attributes(user, tg_user, started)
    end
    log_user(current_user, started)
    current_user
  end

  def self.assign_user_attributes(user, tg_user, started)
    # user.first_name  = tg_user['first_name']
    # user.middle_name = tg_user['last_name']
    user.username  = tg_user['username']
    user.email     = "tg_#{tg_user['id']}@#{ENV.fetch('HOST')}"
    user.password  = Devise.friendly_token[0, 20]
    user.photo_url = tg_user['photo_url']
    user.started   = started
  end

  def self.log_user(user, started)
    return if user.previous_changes.none? || started

    Rails.logger.warn "User #{user.id} has been not correct registered"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id first_name middle_name last_name username address created_at role is_blocked started]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  private

  def reset_confirmation_if_email_changed
    self.confirmed_at = nil
    self.confirmation_token = Devise.friendly_token
    self.confirmation_sent_at = Time.current
  end

  def resend_confirmation_email
    send_confirmation_instructions
  end
end
