module Admin
  class AttachmentsController < Admin::ApplicationController
    before_action :set_attachment, only: [:destroy]

    def destroy
      @attachment.destroy
      head :no_content
    end

    private

    def set_attachment
      @attachment = ActiveStorage::Attachment.find(params[:id])
    end
  end
end
