module Admin
  class MessagesController < Admin::ApplicationController
    before_action :authorize_message, only: :destroy
    before_action :set_user, only: %i[create new]

    def index
      @q_messages = Message.includes(:user).order(created_at: :desc).ransack(params[:q])
      @pagy, @messages = pagy(@q_messages.result.joins(:user), items: 20)
    end

    def new
      @message = @user.messages.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Отправить cообщение'),
        turbo_stream.update(:modal_body, partial: '/admin/messages/new')
      ]
    end

    def create
      @message = Message.new(message_attributes)
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

    def message_attributes
      tg_media_file = find_or_create_tg_media_file
      data          = form_tg_file(tg_media_file)
      data[:markup] = params[:markup] if params[:markup]
      data[:type]   = tg_media_file.file_type.split('/').at(0) if tg_media_file.present?
      { text: message_params[:text], tg_id: @user.tg_id, is_incoming: false }.merge({ data: data })
    end

    def form_tg_file(tg_media_file)
      tg_media_file&.file_id.present? ? { tg_file_id: tg_media_file.file_id } : { media_id: tg_media_file&.id }
    end

    def find_or_create_tg_media_file
      return if message_params[:attachment].blank?

      file_hash = Digest::MD5.file(message_params[:attachment]).hexdigest
      TgMediaFile.find_or_create_by!(file_hash: file_hash) { |media| form_media_attr(media) }
    end

    def form_media_attr(media)
      media.file_type = message_params[:attachment].content_type
      media.original_filename = message_params[:attachment].original_filename
      media.attachment = message_params[:attachment]
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
