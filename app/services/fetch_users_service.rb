class FetchUsersService
  def initialize(filter, user_ids = nil)
    @filter   = filter
    @user_ids = user_ids
  end

  def call
    return [] if @filter.blank?

    send(@filter.to_sym)
  end

  private

  def users
    User.where(id: @user_ids)
  end

  def add_cart
    User.joins(cart: :cart_items)
        .where.missing(:orders)
        .or(User.where.not(orders: { status: %i[shipped processing] }))
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
end
