class PassMailer < ApplicationMailer
  def send_pass(user, password)
    @resource = user
    @password = password
    mail(to: user.email, subject: "Ваш пароль от #{Setting.fetch_value(:app_name)}")
  end
end
