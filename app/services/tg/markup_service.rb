require 'telegram/bot'

module Tg
  class MarkupService
    def initialize(markups)
      @markups = markups
      @app_url = "https://t.me/#{settings[:tg_main_bot]}?startapp"
    end

    def self.call(markups)
      new(markups).form_markup
    end

    def form_markup
      prepare_markups
      return if @keyboards.blank?

      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @keyboards)
    end

    private

    def prepare_markups
      return if @markups.blank?
      return first_msg_buttons if @markups['first_msg']

      @markups[:markup] == 'i_paid' ? form_paid_keyboards : form_keyboards
    end

    def settings
      @settings ||= Setting.all_cached
    end

    def form_keyboards
      @keyboards = []
      @keyboards << catalog_btn if @markups[:markup]&.include? 'to_catalog'
      @keyboards << ask_btn if @markups[:markup]&.include? 'ask_btn'
      form_purchase_paid_btn
      @keyboards += form_ext_url_keyboard if @markups[:markup_ext_url].present?
      @keyboards += form_url_keyboard if @markups[:markup_url].present?
      @keyboards
    end

    def form_purchase_paid_btn
      return unless @markups[:markup]&.include? 'purchase_paid'

      @keyboards << form_callback(@markups[:markup], I18n.t("tg_btn.#{@markups[:markup]}"))
    end

    def form_paid_keyboards
      @keyboards = []
      @keyboards << form_callback(@markups[:markup], I18n.t("tg_btn.#{@markups[:markup]}"))
      @keyboards += form_url_keyboard('carts', 'Изменить заказ')
      @keyboards << ask_btn
      @keyboards
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

    def catalog_btn
      btn_text = ENV.fetch('HOST').include?('mirena') ? 'Заказать' : 'Перейти в каталог'
      form_url_btn(btn_text, @app_url)
    end

    def ask_btn
      form_url_btn('Задать вопрос', settings[:tg_support].to_s)
    end

    def group_btn
      form_url_btn(settings[:group_btn_title], settings[:tg_group])
    end

    def first_msg_buttons
      @keyboards = []
      @keyboards << catalog_btn
      @keyboards << group_btn
      @keyboards << ask_btn
      @keyboards
    end

    def form_url_btn(text, url)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, url: url)]
    end
  end
end
