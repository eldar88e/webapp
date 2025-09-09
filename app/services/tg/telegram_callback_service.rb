module Tg
  class TelegramCallbackService
    HANDLERS = %w[i_paid approve_payment submit_tracking purchase_paid].freeze
    TRACK_CACHE_PERIOD = 5.minutes

    def initialize(bot, message)
      @bot     = bot
      @message = message
    end

    def self.call(bot, message)
      new(bot, message).handle_callback
    end

    def handle_callback
      raise "Callback handler for #{@message.data} not found!" unless HANDLERS.include?(@message.data)

      send(@message.data, @bot, @message)
    end

    private

    def i_paid(_bot, message)
      user         = User.find_by(tg_id: message.from.id)
      order_number = parse_order_number(message.message.text)
      order        = user.orders.find(order_number)
      order.update(status: :paid)
    end

    def approve_payment(bot, message)
      order_number = parse_order_number(message.message.text)
      order        = Order.find(order_number)
      order.update(status: :processing)
      bot.api.delete_message(chat_id: message.message.chat.id, message_id: message.message.message_id)
    end

    def submit_tracking(bot, message)
      order_number = parse_order_number(message.message.text)
      full_name    = parse_full_name(message.message.text)
      msg          = bot.api.send_message(chat_id: message.message.chat.id,
                                          text: I18n.t('tg_msg.set_track_num', order: order_number, fio: full_name))
      save_cache(order_number, message, msg)
    end

    def purchase_paid(bot, message)
      purchase_number = parse_order_number(message.message.text)
      purchase        = Purchase.find(purchase_number)
      purchase.update(status: :shipped)
      new_text = "#{message.message.text}\n\n🚚 В пути"
      edit_message(bot, message, new_text)
    end

    def parse_order_number(text)
      text.match(/№(\d+)/)[1]
    end

    def parse_full_name(text)
      text[/ФИО:\s*(.+?)\n\n/, 1]
    end

    def save_cache(order_number, message, msg)
      Rails.cache.write("user_#{message.message.chat.id}_state",
                        { order_id: order_number, msg_id: message.message.message_id, h_msg: msg.message_id },
                        expires_in: TRACK_CACHE_PERIOD)
    end

    def edit_message(bot, message, text, markup = nil)
      bot.api.edit_message_text(
        chat_id: message.message.chat.id,
        message_id: message.message.message_id,
        text: text,
        parse_mode: 'HTML',
        reply_markup: markup
      )
    end
  end
end
