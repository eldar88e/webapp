class ErrorMailer < ApplicationMailer
  default from: ENV.fetch('EMAIL_FROM', 'noreply@example.com')

  def send_error(error, full_message)
    @error   = error
    @message = full_message
    @user    = User.find_by(tg_id: Setting.fetch_value(:test_id))
    return Rails.logger.error 'User not found for Error mailer' if @user.nil?

    mail(to: @user.email, subject: "Произошла критическая ошибка на сайте #{ENV.fetch('HOST')}!")
  end
end
