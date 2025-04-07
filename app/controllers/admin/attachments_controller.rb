module Admin
  class AttachmentsController < Admin::ApplicationController
    before_action :set_attachment, only: [:destroy]

    def destroy
      @attachment.destroy
      # msg = 'Вложение успешно удалено.'
      render turbo_stream: turbo_stream.remove("attachment_#{@attachment.id}")
    end

    private

    def set_attachment
      @attachment = ActiveStorage::Attachment.find(params[:id])
    end
  end
end
