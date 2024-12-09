module Admin
  module ApplicationHelper
    include Pagy::Frontend

    def format_date(date)
      return date.strftime('%H:%M %d.%m.%Yг.') if date.instance_of?(ActiveSupport::TimeWithZone)

      Time.zone.parse(date).strftime('%H:%M %d.%m.%Yг.') if date.present?
    end
  end
end
