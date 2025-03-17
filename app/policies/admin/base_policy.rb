module Admin
  class BasePolicy < ApplicationPolicy
    def admin_access?
      user.present? && !user.user?
    end

    # class Scope < ApplicationPolicy::Scope; end
  end
end
