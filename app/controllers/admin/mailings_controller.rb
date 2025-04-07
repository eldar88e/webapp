module Admin
  class MailingsController < Admin::ApplicationController
    MARKUP = { markup: 'to_catalog' }.freeze # TODO: менять через форму

    before_action :form_mailing, only: :create

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
      if @mailing.save
        redirect_to admin_mailings_path, notice: t('mailing_success')
      else
        error_notice(@mailing.errors.full_messages, :unprocessable_entity)
      end
    end

    private

    def form_mailing
      @mailing      = current_user.mailings.new(mailing_params)
      @mailing.data = AttachmentService.call(params[:mailing][:attachment]).merge(MARKUP)
    end

    def mailing_params
      params.require(:mailing).permit(:target, :message, :send_at) # TODO: добавить  :scheduled_at
    end
  end
end
