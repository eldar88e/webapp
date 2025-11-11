module Tg
  class TelegramCallbackService
    HANDLERS = %w[i_paid approve_payment submit_tracking purchase_paid review].freeze # TODO: убрать дублирование
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

    def i_paid(bot, message)
      user     = User.find_by(tg_id: message.from.id)
      order_id = parse_order_number(message.message.text)
      order    = user.orders.find(order_id)
      new_text = mark_as_paid(order)
      edit_message(bot, message, "#{message.message.text}\n\n#{new_text}")
    end

    def approve_payment(bot, message)
      text     = message.message.text
      order_id = parse_order_number(text)
      order    = Order.find(order_id)
      result   = order.update(status: :processing)
      return bot.api.delete_message(chat_id: message.message.chat.id, message_id: message.message.message_id) if result

      edit_message(bot, message, "#{text}\n\n❌ Ошибка\n\n#{order.errors.full_messages.join(', ')}")
    end

    def submit_tracking(bot, message)
      order_id  = parse_order_number(message.message.text)
      full_name = parse_full_name(message.message.text)
      text      = I18n.t('tg_msg.set_track_num', order: order_id, fio: full_name)
      msg       = bot.api.send_message(chat_id: message.message.chat.id, text: text)
      save_cache(order_id, message, msg)
    end

    def purchase_paid(bot, message)
      purchase_id = parse_order_number(message.message.text)
      purchase    = Purchase.find(purchase_id)
      purchase.update(status: :shipped)
      new_text = "#{message.message.text}\n\n🚚 В пути"
      edit_message(bot, message, new_text)
    end

    def review(bot, message)
      review_id = parse_order_number(message.message.text)
      review    = Review.find(review_id)
      review.update(approved: true)
      new_text = "#{message.message.text}\n\n✅ Отзыв подтвержден"
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

    def mark_as_paid(order)
      return '✅ Оплачено' if order.status == 'unpaid' && order.update(status: :paid)

      msg = "Failed to update order #{order.id} to paid: #{errors}\n\n#{order.errors.full_messages.join(', ')}"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
      '❌ Ошибка'
    end
  end
end
