module Purchases
  class ReportService
    def initialize(purchase)
      @purchase = purchase
    end

    def self.call(purchase)
      new(purchase).send_report
    end

    def send_report
      send @purchase.status
    end

    private

    def sent_to_supplier
      msg = "📦 Закупка ##{@purchase.id}"
      msg += "\n\n💰 Сумма: #{@purchase.total} ₺"
      msg += I18n.t('purchases.messages.send_supplier', count: @purchase.purchase_items.count)
      msg += "\n\n#{purchase_items_str(true)}"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg)
      send_to_supplier(msg)
    end

    def shipped
      msg = "📦 Закупка ##{@purchase.id} отгружена"
      msg += "\n\n💰 Сумма: #{@purchase.total} ₺"
      msg += I18n.t('purchases.messages.send_supplier', count: @purchase.purchase_items.count)
      msg += "\n\n#{purchase_items_str}"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg)
    end

    def stocked
      msg = "✅ Закупка #️⃣#{@purchase.id} оприходована"
      msg += I18n.t('purchases.messages.send_supplier', count: @purchase.purchase_items.count)
      msg += "\n\n#{purchase_items_str}"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: :courier)
    end

    def cancelled
      msg = "❌ Закупка ##{@purchase.id} отменена"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg)
      send_to_supplier(msg)
    end

    def purchase_items_str(prices = nil)
      @purchase.purchase_items.includes(:product).map.with_index(1) do |item, idx|
        str = "#{idx}. #{item.product.name} – #{item.quantity} шт."
        str += " x #{item.unit_cost}₺ = #{item.line_total}₺" if prices
        str
      end.join("\n")
    end

    def send_to_supplier(msg)
      supplier_tg_id = Setting.fetch_value(:supplier_tg_id)
      return if supplier_tg_id.blank? || msg.blank?

      TelegramJob.perform_later(msg: msg, id: supplier_tg_id)
    end
  end
end
