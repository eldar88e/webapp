module Admin
  module MessagesHelper
    def format_btn(markup)
      if markup['markup'].present?
        I18n.t("tg_btn.#{markup['markup']}")
      elsif markup['markup_url'].present?
        "#{markup['markup_text']}(#{markup['markup_url'].sub('_reviews_new', '').sub('ucts_', ' ')})"
      else
        raise 'No markup data'
      end
    end

    def prepare_html_tag(data)
      file =
        if data['media_id']
          TgMediaFile.find_by(id: data['media_id'])
        elsif data['tg_file_id']
          TgMediaFile.find_by(file_id: data['tg_file_id'])
        else
          raise 'No file data'
        end

      return unless file&.attachment&.attached?

      file.attachment
    end

    # def form_tag(file, data)
    #   if data['type'] == 'video'
    #     video_tag(file.attachment, controls: true, width: 200)
    #   else
    #     image_tag storage_path(file.attachment), class: 'max-w-full h-auto rounded-lg'
    #   end
    # end
  end
end
