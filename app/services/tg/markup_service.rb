require 'telegram/bot'

module Tg
  class MarkupService
    ORDER_BUTTONS = %w[i_paid approve_payment submit_tracking purchase_paid review].freeze

    def initialize(markups)
      @markups   = markups
      @app_url   = "https://t.me/#{settings[:tg_main_bot]}?startapp"
      @keyboards = []
    end

    def self.call(markups)
      new(markups).form_markup
    end

    def form_markup
      return if @markups.blank?

      prepare_markups
      return if @keyboards.blank?

      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @keyboards)
    end

    private

    def prepare_markups
      return first_msg_buttons if @markups[:markup] == 'first_msg'
      return catalog_ask_btn if @markups[:markup] == 'new_order'
      return form_order_keyboards if ORDER_BUTTONS.include? @markups[:markup]

      other_form_keyboards
    end

    def settings
      @settings ||= Setting.all_cached
    end

    def other_form_keyboards
      @keyboards << catalog_btn if @markups[:markup] == 'to_catalog'
      @keyboards << ask_btn if @markups[:markup] == 'ask_btn'
      @keyboards += form_ext_url_keyboard if @markups[:markup_ext_url].present?
      @keyboards += form_url_keyboard if @markups[:markup_url].present?
    end

    def form_order_keyboards
      @keyboards << form_callback(@markups[:markup], I18n.t("tg_btn.#{@markups[:markup]}"))
      return @keyboards if @markups[:markup] != 'i_paid'

      @keyboards += form_url_keyboard('carts', 'Изменить заказ')
      @keyboards << ask_btn
    end

    def catalog_ask_btn
      @keyboards << catalog_btn('Новый заказ')
      @keyboards << ask_btn
    end

    def form_callback(callback, text)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: callback)]
    end

    def form_url_keyboard(markup_url = nil, markup_text = nil)
      texts = [markup_text || @markups[:markup_text]].flatten
      [markup_url || @markups[:markup_url]].flatten.map.with_index do |path, idx|
        url = "#{@app_url}=url=#{path.gsub(%r{\A/|/\z}, '').tr('/', '_')}"
        form_url_btn(texts[idx] || 'Кнопка', url)
      end
    end

    def form_ext_url_keyboard
      texts = [@markups[:markup_ext_text]].flatten
      [@markups[:markup_ext_url]].flatten.map.with_index { |url, idx| form_url_btn(texts[idx] || 'Кнопка', url) }
    end

    def catalog_btn(btn_text = nil)
      btn_text ||= ENV.fetch('HOST').include?('mirena') ? 'Заказать' : I18n.t('tg_btn.to_catalog')
      form_url_btn(btn_text, @app_url)
    end

    def ask_btn
      form_url_btn('Задать вопрос', settings[:tg_support].to_s)
    end

    def group_btn
      form_url_btn(settings[:group_btn_title], settings[:tg_group])
    end

    def first_msg_buttons
      @keyboards << catalog_btn
      @keyboards << group_btn
      @keyboards << ask_btn
    end

    def form_url_btn(text, url)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, url: url)]
    end
  end
end
