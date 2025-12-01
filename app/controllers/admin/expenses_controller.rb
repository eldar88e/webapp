module Admin
  class ExpensesController < ApplicationController
    include Admin::ResourceConcerns

    def index
      @pagy, @resources = pagy Expense.includes([:expenseable]).order(created_at: :desc)
    end

    private

    def current_time(date)
      date.to_datetime.change(hour: Time.current.hour, min: Time.current.min, sec: Time.current.sec)
    end

    def expense_params
      result = params.expect(expense: %i[category description amount expense_date])
      if result[:expense_date].present?
        result[:expense_date] = current_time(result[:expense_date])
      else
        result.delete(:expense_date)
      end
      result
    end
  end
end
