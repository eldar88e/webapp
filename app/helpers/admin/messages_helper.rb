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

    def form_attachment(data)
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
  end
end
