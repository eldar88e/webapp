class ApplicationMailer < ActionMailer::Base
  default from: "#{(Setting.fetch_value(:app_name) || 'Сайт').capitalize} <#{ENV.fetch('EMAIL_FROM', 'norep@exm.com')}>"
  layout 'mailer'
end
