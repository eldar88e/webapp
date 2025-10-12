class GroupDatesService
  class << self
    def build_date_range(start_date, end_date, group_by)
      case group_by.to_s
      when 'day' then (start_date.to_date..end_date.to_date).to_a
      when 'week' then (start_date.beginning_of_week.to_date..end_date.end_of_week.to_date).step(7).map(&:to_date)
      when 'month' then (start_date.beginning_of_month.to_date..end_date.end_of_month.to_date).map(&:beginning_of_month).uniq
      when 'year' then (start_date.beginning_of_year.to_date..end_date.end_of_year.to_date).map(&:beginning_of_year).uniq
      else (start_date.to_date..end_date.to_date).to_a
      end
    end

    def group_by_period(period)
      case period.to_s
      when 'day'   then :to_date
      when 'week'  then :to_date
      when 'month' then :to_date
      when 'year'  then :beginning_of_month
      else :to_date
      end
    end
  end
end
