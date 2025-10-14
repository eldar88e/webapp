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
          return
        end

      return unless file&.attachment&.attached?

      file.attachment.content_type.start_with?('application') ? storage_path(file.attachment) : url_for(file.attachment)
    end

    def name_user(user)
      name = "#{user.middle_name} #{user.first_name}".presence || user.full_name_raw.presence || user.tg_id
      return "#{name[0...20]}..." if name.size > 23

      name
    end

    def format_date(date)
      return if date.blank?

      new_date = prefix_date(date)[date.to_date]
      return new_date if new_date.present?
      return date.strftime("%H:%M\u00A0%d.%m") if date.year == Time.current.year

      date.strftime("%H:%M\u00A0%d.%m.%Yг.")
    end

    def prefix_date(date)
      {
        Time.current.to_date => date.strftime('%H:%M'),
        (Time.current.to_date - 1.day) => "Вчера,\u00A0#{date.strftime('%H:%M')}"
      } # TODO: add this week days
    end

    def preview_media(data)
      return if data.blank?

      attachment_path = form_attachment(data)
      return if attachment_path.blank?
      return image_tag attachment_path, class: 'w-5 h-5' if data['type'].start_with?('image')
      return video_tag attachment_path, class: 'w-5 h-5' if data['type'].start_with?('video')

      if data['type'] == 'application/pdf'
        render Admin::IconComponent.new name: :pdf
      else
        '???'
      end
    end
  end
end
