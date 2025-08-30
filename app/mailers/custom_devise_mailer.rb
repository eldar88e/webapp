class CustomDeviseMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers

  default template_path: 'devise/mailer'

  def confirmation_instructions(record, token, opts = {})
    # nothing not send because email is generated with system
  end
end
