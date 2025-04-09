module Admin
  class MessagesController < Admin::ApplicationController
    before_action :authorize_message, only: :destroy
    before_action :set_user, only: %i[create new]
    before_action :form_message, only: :create

    def index
      @q_messages       = Message.includes(:user).ransack(params[:q])
      @q_messages.sorts = 'created_at desc' if params[:q].nil?
      @pagy, @messages  = pagy(@q_messages.result.joins(:user))
    end

    def new
      @message = @user.messages.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Отправить cообщение'),
        turbo_stream.update(:modal_body, partial: '/admin/messages/new')
      ]
    end

    def create
      if @message.save
        render turbo_stream: [
          turbo_stream.prepend(:messages, partial: '/admin/messages/message', locals: { message: @message }),
          success_notice('Сообщение успешно отправлено')
        ]
      else
        error_notice(@message.errors.full_messages)
      end
    end

    def destroy
      @message = Message.find(params[:id])
      @message.destroy!
      msg = 'Сообщение было успешно удалено.'
      TelegramJob.perform_later(id: @message.tg_id, msg_id: @message.tg_msg_id, method: 'delete_msg') if params[:tg_msg]
      msg += "\nВ телеграм и БД." if params[:tg_msg]
      render turbo_stream: [turbo_stream.remove(@message), success_notice(msg)]
    end

    private

    def form_message
      @message      = Message.new({ text: message_params[:text], tg_id: @user.tg_id, is_incoming: false })
      @message.data = AttachmentService.call(params[:message][:attachment])
    end

    def set_user
      @user = User.find(params[:user_id] || message_params[:user_id])
    end

    def authorize_message
      authorize [:admin, Message]
    end

    def message_params
      params.require(:message).permit(:text, :user_id, :attachment)
    end
  end
end
