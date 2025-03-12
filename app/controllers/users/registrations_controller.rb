# frozen_string_literal: true

module Users
  class RegistrationsController < ApplicationController
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
  end
end
