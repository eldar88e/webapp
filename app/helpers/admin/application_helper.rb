module Admin
  module ApplicationHelper
    include Pagy::Frontend

    def format_date(date)
      return date.strftime('%H:%M %d.%m.%Yг.') if date.instance_of?(ActiveSupport::TimeWithZone)

      Time.zone.parse(date).strftime('%H:%M %d.%m.%Yг.') if date.present?
    end

    def blue_btn_styles
      'text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm ' \
      'px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800'
    end
  end
end
