class FetchUsersService
  def initialize(user_ids = nil)
    @user_ids = user_ids
  end

  def self.call(filter, user_ids)
    return [] if filter.blank?

    new(user_ids).send(filter.to_sym)
  end

  private

  def users
    User.where(id: @user_ids)
  end

  def add_cart
    User.joins(cart: :cart_items)
        .where(cart_items: { created_at: ...1.week.ago })
        .where.missing(:orders)
        .or(User.where.not(orders: { status: %i[paid processing shipped] }))
        .distinct
  end

  def ordered
    User.joins(:orders).where.not(orders: { id: nil }).distinct
  end

  def no_ordered
    User.where.missing(:orders).distinct
  end

  def all_users
    User.all
  end

  def blocked
    User.where(is_blocked: true)
  end

  def subscriptions
    User.joins(:product_subscriptions).distinct
  end
end
