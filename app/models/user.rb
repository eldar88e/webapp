class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :orders, dependent: :destroy
  has_one :cart, dependent: :destroy

  validates :tg_id, presence: true, uniqueness: true
  validates :postal_code, numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999 }

  def cart
    super || create_cart
  end

  def full_name
    "#{middle_name} #{first_name} #{last_name}"
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
                        .where(orders: { created_at: start_date..end_date })
                        .distinct
                        .count

    return 0 if total_customers.zero?

    repeat_customers = joins(:orders)
                         .where(orders: { created_at: start_date..end_date })
                         .group('users.id')
                         .having('COUNT(orders.id) > 1')
                         .count
                         .size

    [repeat_customers.to_f, total_customers.to_f] # .round(2)
  end

  def self.registered_count_grouped_by_period(start_date, end_date, period)
    where(created_at: start_date..end_date)
      .group('DATE(created_at)')
      .count
  end

  def self.find_or_create_by_tg(tg_user)
    tg_user = tg_user.as_json if tg_user.instance_of?(Telegram::Bot::Types::Chat)
    self.find_or_create_by(tg_id: tg_user['id']) do |user|
      user.username    = tg_user['username']
      user.first_name  = tg_user['first_name']
      user.middle_name = tg_user['last_name']
      user.email       = "telegram_user_#{tg_user["id"]}@example.com"
      user.password    = Devise.friendly_token[0, 20]
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name middle_name last_name username address created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end
end
