class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('EMAIL_FROM', 'noreply@example.com')
  layout 'mailer'
end
