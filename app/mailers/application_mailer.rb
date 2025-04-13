class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('EMAIL_FROM', 'noreply@tgapp.online')
  layout 'mailer'
end
