module Admin
  class MessagesController < Admin::ApplicationController
    before_action :authorize_message, only: :destroy
    before_action :set_user, :build_message, only: :create
    before_action :set_chats, :set_chats_page, :render_msg, only: :index

    def index
      @chats_page, @chats = pagy(@chats, limit: 30, page_param: :chats_page)
      @current_chat       = params[:chat_id].present? ? User.find_by!(tg_id: params[:chat_id]) : @chats.first
      fetch_messages(@current_chat)
    end

    def create
      if @message.save
        render turbo_stream: success_notice('Сообщение успешно отправлено')
      else
        error_notice(@message.errors.full_messages)
      end
    end

    def destroy
      @message = Message.find(params[:id])
      @message.destroy!
      render turbo_stream: [turbo_stream.remove(@message), success_notice('Сообщение было успешно удалено.')]
    end

    private

    def render_msg
      return if params[:chat_open].blank? || params[:chat_id].blank?

      user = User.find_by!(tg_id: params[:chat_id])
      fetch_messages(user)
      render turbo_stream: turbo_stream.update('messages', partial: '/admin/messages/messages')
    end

    def set_chats_page
      params[:chats_page] ||= session[:chats_page] || 1
      session[:chats_page] = params[:chats_page]
    end

    def build_message
      @message      = @user.messages.build(text: message_params[:text], is_incoming: false)
      @message.data = AttachmentService.call(params[:message][:attachment])
    end

    def fetch_messages(user)
      messages         = user&.messages&.order(created_at: :desc) || Message.none
      @pagy, @messages = pagy(messages, limit: 50)
      @messages        = @messages.reverse
    end

    def set_chats
      # @chats = User.joins('INNER JOIN messages ON (messages.tg_id = users.tg_id)')
      #              .select('users.*, MAX(messages.created_at)')
      #              .group('users.id')
      #              .order('MAX(messages.created_at) DESC')
      #              .includes(:messages)
      @chats = User.joins('INNER JOIN (
                      SELECT DISTINCT ON (tg_id)
                        tg_id,
                        created_at AS last_message_at
                      FROM messages
                      ORDER BY tg_id, created_at DESC
                    ) AS last_messages ON last_messages.tg_id = users.tg_id')
                   .select('users.*, last_messages.last_message_at')
                   .order('last_messages.last_message_at DESC')
                   .includes(:messages)
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
