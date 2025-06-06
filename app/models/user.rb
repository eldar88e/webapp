class User < ApplicationRecord
  EMAIL_HOST = 'tgapp.online'.freeze

  attr_accessor :bonus_balance_diff

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
  has_many :subscriptions_products, through: :product_subscriptions, source: :product
  has_many :subscribed_products, through: :product_subscriptions, source: :product
  has_many :mailings, dependent: :destroy
  has_many :ahoy_visits, class_name: 'Ahoy::Visit', dependent: :destroy
  has_many :ahoy_events, class_name: 'Ahoy::Event', dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_products, through: :favorites, source: :product
  has_many :bonus_logs, dependent: :destroy
  belongs_to :account_tier, optional: true

  # validates :order_count, numericality: { greater_than_or_equal_to: 0 }
  validates :bonus_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :tg_id, presence: true, uniqueness: true
  validates :email, 'valid_email_2/email': { strict_mx: true, disposable: true }
  validates :postal_code, numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: 100_000,
                                          less_than_or_equal_to: 999_999 }

  before_update :reset_confirmation_if_email_changed, if: :will_save_change_to_email?
  before_update :store_bonus_balance_diff, if: -> { bonus_balance_changed? }
  after_update :resend_confirmation_email, if: :saved_change_to_email?
  after_update :check_and_upgrade_account_tier
  after_commit :notify_update_account_tier, if: -> { previous_changes[:account_tier_id].present? }
  after_commit :notify_bonus_user, on: :update, if: -> { bonus_balance_diff.present? && bonus_balance_diff.positive? }

  def admin?
    role == 'admin'
  end

  def moderator?
    role == 'moderator'
  end

  def manager?
    role == 'manager'
  end

  def add_bonus(amount, reason)
    transaction do
      bonus_logs.create!(bonus_amount: amount, reason: reason)
      self.bonus_balance += amount
      save!
    end
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

  def full_name_raw
    "#{first_name_raw} #{last_name_raw}"
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
    current_user = find_or_create_by!(tg_id: tg_user['id']) do |user|
      assign_user_attributes(user, tg_user, started)
    end
    log_user(current_user, started)
    current_user
  end

  def self.assign_user_attributes(user, tg_user, started)
    user.first_name_raw = tg_user['first_name']
    user.last_name_raw  = tg_user['last_name']
    user.username  = tg_user['username']
    user.email     = "tg_#{tg_user['id']}@#{EMAIL_HOST}"
    user.password  = Devise.friendly_token[0, 20]
    user.photo_url = tg_user['photo_url']
    user.started   = started
  end

  def self.log_user(user, started)
    return if user.previous_changes.none? || started

    Rails.logger.warn "User #{user.id} has been not correct registered"
  end

  def next_account_tier
    account_tier ? account_tier.next : AccountTier.first_level
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id first_name middle_name last_name username address created_at role is_blocked started email]
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
    Devise::Mailer.confirmation_instructions(self, confirmation_token).deliver_later
    # TODO: tg notice
  end

  def check_and_upgrade_account_tier
    return if !saved_change_to_attribute?(:order_count) || order_count.zero?
    return update(account_tier: AccountTier.first_level) if account_tier.blank?

    next_tier = account_tier.next
    update(account_tier: next_tier) if next_tier && order_count >= next_tier.order_threshold
  end

  def notify_update_account_tier
    AccountTierNoticeJob.set(wait: 0.3.seconds).perform_later(id)
  end

  def notify_bonus_user
    UserBonusNoticeJob.set(wait: 0.5.seconds).perform_later(id, bonus_balance_diff)
  end

  def store_bonus_balance_diff
    self.bonus_balance_diff = bonus_balance - (bonus_balance_before_last_save || 0)
  end
end
