# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController

    # TODO: поменять на редактирование password
    def edit_email; end

    def change_email
      if current_user.update(user_email_params)
        render turbo_stream: success_notice(t('.success'))
        # redirect_to root_path, notice: t('.success')
      else
        error_notice t('.failure')
      end
    end
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    def new
      # TODO: убрать в дальнейшем и исследовать работает ли регистрация через post-запрос
      redirect_to root_path
    end

    def update
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
