module Admin
  class MessagePolicy < Admin::BasePolicy
    def destroy?
      user.admin? || user.moderator?
    end
  end
end
