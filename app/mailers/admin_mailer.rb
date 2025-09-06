class AdminMailer < ApplicationMailer
  default from: ENV.fetch('EMAIL_FROM')

  def send_error(error, full_message = nil, subject = nil)
    @error   = error
    @message = full_message
    @user    = User.find_by(tg_id: Setting.fetch_value(:test_id))
    return Rails.logger.error 'User not found for Error mailer' if @user.nil?

    mail(to: @user.email, subject: subject || "Произошла критическая ошибка на сайте #{ENV.fetch('HOST')}!")
  end
end
