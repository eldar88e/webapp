class AdminChatChannel < ApplicationCable::Channel
  def subscribed
    # binding.pry

    # chat = User.find(params[:chat_id])
    # stream_for chat

    stream_from 'admin_chat_1'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
