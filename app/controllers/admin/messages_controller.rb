module Admin
  class MessagesController < Admin::ApplicationController
    # before_action :authorize_message, only: :destroy
    before_action :set_user, :form_message, only: :create
    before_action :set_chats, only: :index

    def index
      @pages, @chats   = pagy(@chats, limit: 30, page_param: :chats_page)
      @current_chat    = User.find_by(tg_id: params[:chat_id]) || @chats.first
      messages         = @current_chat&.messages&.order(created_at: :desc) || Message.none
      @pagy, @messages = pagy(messages, limit: 50)
      @messages        = @messages.reverse
    end

    def create
      if @message.save
        render turbo_stream: success_notice('Сообщение успешно отправлено')
      else
        error_notice(@message.errors.full_messages)
      end
    end

    def destroy
      raise 'Not implemented'
    end

    private

    def form_message
      @message      = Message.new({ text: message_params[:text], tg_id: @user.tg_id, is_incoming: false })
      @message.data = AttachmentService.call(params[:message][:attachment])
    end

    def set_chats
      @chats = User.joins('INNER JOIN messages ON (messages.tg_id = users.tg_id)')
                   .select('users.*, MAX(messages.created_at)')
                   .group('users.id')
                   .order('MAX(messages.created_at)').includes(:messages)
    end

    def set_user
      @user = User.find(params[:user_id] || message_params[:user_id])
    end

    # def authorize_message
    #   authorize [:admin, Message]
    # end

    def message_params
      params.require(:message).permit(:text, :user_id, :attachment)
    end
  end
end
