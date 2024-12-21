module Admin
  class MailingsController < Admin::ApplicationController
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
        MailingJob.perform_later(
          filter: @mailing.filter.to_sym,
          message: @mailing.message
        )
        redirect_to admin_mailings_path, notice: 'Рассылка успешно запланирована!'
      else
        error_notice(@mailing.errors.full_messages, :unprocessable_entity)
      end
    end

    private

    def mailing_params
      params.permit(:filter, :message, :scheduled_at) # TODO: .require(:mailing)
    end
  end
end
