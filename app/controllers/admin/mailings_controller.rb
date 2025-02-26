module Admin
  class MailingsController < Admin::ApplicationController
    MARKUP = 'mailing'.freeze

    def index; end

    def new
      @mailing = Mailing.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Запустить рассылку'),
        turbo_stream.update(:modal_body, partial: '/admin/mailings/new')
      ]
    end

    def create
      @mailing = Mailing.new(mailing_params)
      if @mailing.valid?
        # TODO: set scheduled_at: @mailing.scheduled_at
        MailingJob.perform_later(filter: @mailing.filter, message: @mailing.message, markup: { markup: MARKUP })
        redirect_to admin_mailings_path, notice: t('mailing_success')
      else
        error_notice(@mailing.errors.full_messages, :unprocessable_entity)
      end
    end

    private

    def mailing_params
      params.require(:mailing).permit(:filter, :message, :scheduled_at)
    end
  end
end
