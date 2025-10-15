module Admin
  module MessagesHelper
    ICONS_PARAMS = {
      big: { image: 'w-full max-w-150 rounded-lg', video: 'w-full max-w-150 rounded-lg', pdf: '32' },
      thumb: { image: 'w-5 h-5', video: 'w-5 h-5', pdf: '20' }
    }.freeze

    def format_btn(markup)
      if markup['markup'].present?
        I18n.t("tg_btn.#{markup['markup']}")
      elsif markup['markup_url'].present?
        "#{markup['markup_text']}(#{markup['markup_url'].sub('_reviews_new', '').sub('ucts_', ' ')})"
      else
        raise 'No markup data'
      end
    end

    def find_tg_media_file(data)
      if data['media_id']
        TgMediaFile.find_by(id: data['media_id'])
      elsif data['tg_file_id']
        TgMediaFile.find_by(file_id: data['tg_file_id'])
      end
    end

    def build_full_path(attachment)
      return unless attachment&.attached?

      attachment.content_type.start_with?('application') ? url_for(attachment) : storage_path(attachment)
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

    # def preview_media(data)
    #   return if data.blank?
    #
    #   media_file = find_tg_media_file(data)
    #   attachment = media_file&.attachment
    #   url        = build_full_path(attachment)
    #   return if url.blank?
    #
    #   return image_tag url, class: 'w-5 h-5' if attachment.content_type.start_with?('image')
    #   return video_tag url, class: 'w-5 h-5' if attachment.content_type.start_with?('video')
    #   return render Admin::IconComponent.new name: :pdf if attachment.content_type == 'application/pdf'
    #
    #   '???'
    # end

    def preview_media(data, params = :thumb)
      media_file = find_tg_media_file(data)
      attachment = media_file&.attachment
      url        = build_full_path(attachment)
      return if url.blank?
      return build_icon(attachment.content_type, url, params) if params == :thumb

      link_to build_icon(attachment.content_type, url, params), url, data: { fancybox: 'gallery' }
    end

    def build_icon(content_type, url, params)
      if content_type.start_with?('image')
        image_tag url, class: ICONS_PARAMS[params][:image]
      elsif content_type.start_with?('video')
        video_tag url, controls: true, class: ICONS_PARAMS[params][:video]
      elsif content_type == 'application/pdf'
        render Admin::IconComponent.new name: :pdf, width: ICONS_PARAMS[params][:pdf]
      else
        params == :thumb ? '???' : "Unknown file type(#{content_type})"
      end
    end
  end
end
