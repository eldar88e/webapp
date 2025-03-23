module Admin
  class NewMessagesController < Admin::ApplicationController
    def index
      @q_messages = Message.select('DISTINCT ON (messages.tg_id) messages.*')
                           .order('messages.tg_id, messages.created_at DESC').ransack(params[:q])
      @pagy, @messages = pagy(@q_messages.result, items: 20)
    end

    def show
      chat = Message.where(tg_id: params[:id]).order(created_at: :desc)
      @pagy, @chat = pagy(chat, items: 20)
      render turbo_stream: turbo_stream.update(:chat, partial: 'admin/new_messages/show')
    end
  end
end
