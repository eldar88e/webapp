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
      msg = "📦 Закупка №#{@purchase.id}"
      msg += "\n\n💰 Сумма: #{@purchase.total} ₺"
      msg += I18n.t('purchases.messages.send_supplier', count: @purchase.purchase_items.count)
      msg += "\n\n#{purchase_items_str(true)}"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids), markup: 'purchase_paid')
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:ceo_tg_id), markup: 'purchase_paid')
      send_to_supplier(msg)
    end

    def shipped
      Rails.logger.info "Закупка №#{@purchase.id} отгружена"
      send_to_supplier("Оплатили закупку №#{@purchase.id}. Проверьте, пожалуйста")
    end

    def stocked
      msg = "✅ Закупка №#{@purchase.id} оприходована"
      msg += "\n\nОбновлены остатки #{@purchase.purchase_items.count} товаров:\n\n#{stoked_str}"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: :courier)
      send_to_supplier "✅ Закупка №#{@purchase.id} принята"
    end

    def cancelled
      msg = "❌ Закупка №#{@purchase.id} отменена"
      Rails.logger.info msg
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
      TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:ceo_tg_id))
      send_to_supplier(msg)
    end

    def purchase_items_str(prices = nil)
      @purchase.purchase_items.includes(:product).map.with_index(1) do |item, idx|
        str = "#{idx}. #{item.product.name} – #{item.quantity} шт."
        str += " x #{item.unit_cost}₺ = #{item.line_total}₺" if prices
        str
      end.join("\n")
    end

    def stoked_str
      @purchase.purchase_items.includes(:product).map.with_index(1) do |item, idx|
        "#{idx}. #{item.product.name} – #{item.product.stock_quantity} шт."
      end.join("\n")
    end

    def send_to_supplier(msg)
      supplier_tg_id = Setting.fetch_value(:supplier_tg_id)
      return if supplier_tg_id.blank? || msg.blank?

      tg_token_supplier = Setting.fetch_value(:tg_token_supplier)
      TelegramJob.perform_later(msg: msg, id: supplier_tg_id, tg_token: tg_token_supplier)
    end
  end
end
