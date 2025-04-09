module Admin
  class NewMessagesController < Admin::ApplicationController
    def index
      @q_messages = Message.select('DISTINCT ON (messages.tg_id) messages.*')
                           .order('messages.tg_id, messages.created_at DESC').ransack(params[:q])
      @pagy, @messages = pagy(@q_messages.result)
    end

    def show
      @pagy, @chat = pagy Message.where(tg_id: params[:id]).order(created_at: :desc)
      render turbo_stream: turbo_stream.update(:chat, partial: 'admin/new_messages/show')
    end
  end
end
