# frozen_string_literal: true

module Users
  class RegistrationsController < ApplicationController
    def edit_email; end

    def change_email
      if current_user.update(user_email_params)
        render turbo_stream: success_notice(t('.success'))
        # redirect_to root_path, notice: t('.success')
      else
        error_notice t('.failure')
      end
    end

    def new
      super
    end

    def edit
      render turbo_stream: turbo_stream.update(:modal, partial: '/devise/registrations/edit')
    end

    def update
      return error_notice(t('required_fields')) unless required_fields_filled?

      if current_user.update(user_params)
        render turbo_stream: [
          turbo_stream.append(:modal, '<script>closeModal();</script>'.html_safe),
          success_notice('Ваша учетная запись изменена.')
        ]
      else
        error_notice(current_user.errors.full_messages)
      end
    end

    private

    def user_email_params
      params.require(:user).permit(:email)
    end
  end
end
