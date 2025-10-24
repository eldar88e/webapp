# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    def new
      redirect_to root_path
    end

    def create
      redirect_to root_path
    end

    def update
      return super if params[:user][:password].present?
      return error_notice(t('.required_fields')) unless required_fields_filled?

      if current_user.update(user_params)
        render turbo_stream: success_notice('Ваша учетная запись изменена.')
      else
        error_notice current_user.errors.full_messages
      end
    end

    private

    def user_email_params
      params.require(:user).permit(:email)
    end
  end
end
