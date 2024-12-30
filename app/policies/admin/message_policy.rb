module Admin
  class MessagePolicy < Admin::BasePolicy
    def destroy?
      user.admin?
    end
  end
end
