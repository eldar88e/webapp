module Admin
  class MailingsController < Admin::ApplicationController
    def index
      @mailings = Mailing.order(send_at: :desc).includes(:user)
    end

    def new
      @mailing = Mailing.new(target: nil)
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Запустить рассылку'),
        turbo_stream.update(:modal_body, partial: '/admin/mailings/new')
      ]
    end

    def create
      @mailing         = Mailing.new(mailing_params)
      @mailing.send_at = Time.current + 1.minute
      @mailing.user    = current_user
      if @mailing.save
        #MailingJob.perform_later(filter: @mailing.filter, message: @mailing.message, markup: { markup: MARKUP })
        redirect_to admin_mailings_path, notice: t('mailing_success')
      else
        error_notice(@mailing.errors.full_messages, :unprocessable_entity)
      end
    end

    private

    def mailing_params
      params.require(:mailing).permit(:target, :message, :send_at)
    end
  end
end
