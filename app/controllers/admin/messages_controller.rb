module Admin
  class MessagesController < Admin::ApplicationController

    def new
      @message = Message.new
      @user_id = params[:user_id]
      @fio     = params[:fio]
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Отправить cообщение'),
        turbo_stream.update(:modal_body, partial: '/admin/messages/new')
      ]
    end

    def create
      MailingJob.perform_later(filter: :user, message: message_params[:text], user_id: message_params[:user_id])
      render turbo_stream: success_notice('Сообщение успешно отправленно в очередь!')
    end

    def index
      return redirect_to admin_dashboard_path if current_user.id != 2

      @q_messages = Message.includes(:user).order(created_at: :desc).ransack(params[:q])
      @pagy, @messages = pagy(@q_messages.result.joins(:user), items: 20)
    end

    private

    def message_params
      params.require(:message).permit(:text, :user_id)
    end
  end
end
