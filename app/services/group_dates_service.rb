class GroupDatesService
  class << self
    def build_date_range(start_date, end_date, group_by)
      case group_by.to_s
      # when 'day' then (start_date.to_date..end_date.to_date).to_a
      when 'week' then (start_date.beginning_of_week.to_date..end_date.end_of_week.to_date).step(7).map(&:to_date)
      when 'month' then range_dates(start_date, end_date)
      when 'year' then range_dates(start_date, end_date, 'year')
      else (start_date.to_date..end_date.to_date).to_a
      end
    end

    def group_by_period(period)
      case period.to_s
      # when 'day' then :to_date
      when 'week' then :beginning_of_week
      when 'month' then :beginning_of_month
      when 'year' then :beginning_of_year
      else :to_date
      end
    end

    private

    def range_dates(start_date, end_date, type = 'month')
      (start_date.send("beginning_of_#{type}").to_date..end_date.send("end_of_#{type}").to_date)
        .map { |date| date.send("beginning_of_#{type}").to_date }.uniq
    end
  end
end
