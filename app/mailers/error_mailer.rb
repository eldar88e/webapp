class ErrorMailer < ApplicationMailer
  default from: "support@#{ENV.fetch('HOST')}"

  def send_error(error, full_message)
    @error   = error
    @message = full_message
    @user    = User.find_by(tg_id: Setting.fetch_value(:test_id))
    mail(to: @user.email, subject: "Произошла критическая ошибка на сайте #{ENV.fetch('HOST')}!")
  end
end
