require 'telegram/bot'

module Tg
  class MarkupService
    def initialize(markups)
      @markups = markups
      @app_url = "https://t.me/#{settings[:tg_main_bot]}?startapp"
      form_keyboards if @markups.present?
    end

    def self.call(markups)
      new(markups).form_markup
    end

    def form_markup
      return if @keyboards.blank?

      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @keyboards)
    end

    private

    def settings
      @settings ||= Setting.all_cached
    end

    def form_keyboards
      @keyboards = []
      @keyboards << catalog_btn if @markups[:markup]&.include? 'to_catalog'
      @keyboards << ask_btn if @markups[:markup]&.include? 'ask_btn'
      @keyboards += form_ext_url_keyboard if @markups[:markup_ext_url].present?
      @keyboards += form_url_keyboard if @markups[:markup_url].present?
      @keyboards
    end

    def callback_data(callback, text)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: callback)]
    end

    def form_url_keyboard
      texts = [@markups[:markup_text]].flatten
      [@markups[:markup_url]].flatten.map.with_index do |path, idx|
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

    def form_url_btn(text, url)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, url: url)]
    end
  end
end
