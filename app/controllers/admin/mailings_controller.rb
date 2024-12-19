module Admin
  class MailingsController < Admin::ApplicationController
    def index
      @mailing = Mailing.new
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
        render :new, status: :unprocessable_entity
      end
    end

    private

    def mailing_params
      params.permit(:filter, :message, :scheduled_at) # TODO: .require(:mailing)
    end
  end
end
