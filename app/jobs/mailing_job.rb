class MailingJob < ApplicationJob
  queue_as :default
  MARKUP = 'mailing'.freeze

  def perform(**args)
    filter  = args[:filter] # :ordered no_ordered
    message = args[:message]
    user_id = args[:user_id]

    return send_message(message, user_id) if user_id && filter == :user

    clients =
      case filter
      when :ordered
        User.joins(:orders).where.not(orders: { id: nil }).distinct
      when :no_ordered
        User.left_joins(:orders).where(orders: { id: nil }).distinct
      when :all
        User.all
      else
        return Rails.logger.warn("#{self.class} | #{filter} is not a valid filter")
      end

    clients.each do |client|
      result = TelegramService.call(message, client.tg_id, markup: MARKUP)
      sleep 0.3
      result # TODO: можно записать в БД содержит или tg_msg_id или ошибку
    end
    TelegramService.call('Рассылка успешно завершена.', Setting.fetch_value(:admin_ids))
  end

  private

  def send_message(message, id)
    user  = User.find(id)
    tg_id = user&.tg_id
    return if tg_id.nil? || message.blank?

    result = TelegramService.call(message, tg_id)
    if result.instance_of?(Integer)
      Message.create(tg_id: tg_id, text: message, is_incoming: false)
    else
      Message.create(tg_id: tg_id, text: result.message, is_incoming: false)
    end
  end
end
