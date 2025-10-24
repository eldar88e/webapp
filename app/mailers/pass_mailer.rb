class PassMailer < ApplicationMailer
  def send_pass(user)
    @resource = user
    mail(to: user.email, subject: "Ваш пароль от #{Setting.fetch_value(:app_name)}")
  end
end
