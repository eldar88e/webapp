module Admin
  module ApplicationHelper
    include Pagy::Frontend

    def format_date(date)
      return date.strftime('%H:%M %d.%m.%Yг.') if date.instance_of?(ActiveSupport::TimeWithZone)

      Time.zone.parse(date).strftime('%H:%M %d.%m.%Yг.') if date.present?
    end

    def form_price(price, currency = '₽')
      MoneyService.price_to_s(price, currency)
    end

    def stat_value(value, suffix: nil, zero_text: '—')
      if value&.zero?
        content_tag :div, zero_text, class: 'text-center'
      else
        safe_join [value.to_s, suffix].compact, "\u00A0"
      end
    end
  end
end
