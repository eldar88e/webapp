module Admin
  class MessagesController < Admin::ApplicationController
    before_action :authorize_message, only: :destroy

    def index
      @q_messages = Message.includes(:user).order(created_at: :desc).ransack(params[:q])
      @pagy, @messages = pagy(@q_messages.result.joins(:user), items: 20)
    end

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
      MailingJob.perform_later(filter: 'user', message: message_params[:text], user_id: message_params[:user_id])
      render turbo_stream: success_notice('Сообщение успешно отправленно в очередь!')
    end

    def destroy
      @message = Message.find(params[:id])
      @message.destroy!
      msg = 'Сообщение было успешно удалено.'
      TelegramService.delete_msg('', @message.tg_id, @message.tg_msg_id) if params[:tg_msg]
      msg += ' В телеграм и БД.' if params[:tg_msg]
      render turbo_stream: [
        turbo_stream.remove(@message),
        success_notice(msg)
      ]
    end

    private

    def authorize_message
      authorize [:admin, Message]
    end

    def message_params
      params.require(:message).permit(:text, :user_id)
    end
  end
end
