require 'telegram/bot'

module Tg
  class MarkupService
    def initialize(data)
      @data      = data[:markup] || {}
      @keyboards = form_keyboards
    end

    def self.call(data)
      new(data).form_markup
    end

    def form_markup
      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: @keyboards)
    end

    private

    def settings
      @settings ||= Setting.all_cached
    end

    def form_keyboards
      [
        (startapp_btn if @data[:markup]&.include? 'to_catalog'),
        (ask_btn if @data[:markup]&.include? 'ask_btn'),
        (form_url_keyboard(@data[:markup_ext_url]) if @data[:markup_ext_url].present?),
        (form_url_keyboard if @data[:markup_url].present?)
      ].compact
    end

    def callback_data(callback, text)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: callback)]
    end

    def form_url_keyboard(url = nil)
      url ||= "https://t.me/#{settings[:tg_main_bot]}?startapp=url=#{@data[:markup_url]}"
      form_url_btn @data[:markup_text] || 'Кнопка', url
    end

    def startapp_btn(btn_text = 'Перейти в каталог')
      form_url_btn btn_text, "https://t.me/#{settings[:tg_main_bot]}?startapp"
    end

    def ask_btn
      form_url_btn('Задать вопрос', settings[:tg_support].to_s)
    end

    def form_url_btn(text, url)
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, url: url)]
    end
  end
end
