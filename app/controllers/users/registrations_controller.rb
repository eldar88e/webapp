# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  def edit
    render turbo_stream: turbo_stream.update(:modal, partial: "/devise/registrations/edit")
  end

  def update
    return error_notice(t('required_fields')) unless required_fields_filled?

    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      render turbo_stream: [
        turbo_stream.append(:modal, "<script>closeModal();</script>".html_safe),
        success_notice('Ваша учетная запись изменена.')
      ]
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      resource.update_without_password(params)
    else
      super
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :middle_name, :last_name, :phone_number, :address, :postal_code, :street, :home, :apartment, :build
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name, :middle_name, :last_name, :phone_number, :address, :postal_code, :street, :home, :apartment, :build
    ])
  end
end
