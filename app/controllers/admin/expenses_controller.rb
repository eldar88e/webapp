module Admin
  class ExpensesController < ApplicationController
    before_action :set_expense, only: %i[edit update destroy]

    def index
      @pagy, @expenses = pagy Expense.order(created_at: :desc)
    end

    def new
      @expense = Expense.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить расход'),
        turbo_stream.update(:modal_body, partial: '/admin/expenses/form', locals: { method: :post })
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать расход'),
        turbo_stream.update(:modal_body, partial: '/admin/expenses/form', locals: { method: :patch })
      ]
    end

    def create
      @expense = Expense.new(expense_params)
      if @expense.save
        render turbo_stream: [
          turbo_stream.prepend(:expenses, partial: '/admin/expenses/expense', locals: { expense: @expense }),
          success_notice('Расход успешно добавлен.')
        ]
      else
        error_notice @expense.errors.full_messages
      end
    end

    def update
      if @expense.update(expense_params)
        render turbo_stream: [
          turbo_stream.replace(@expense, partial: '/admin/expenses/expense', locals: { expense: @expense }),
          success_notice('Расход успешно обновлен.')
        ]
      else
        error_notice @expense.errors.full_messages
      end
    end

    def destroy
      @expense.destroy!
      render turbo_stream: [turbo_stream.remove(@expense), success_notice('Расход успешно удален.')]
    end

    private

    def current_time(date)
      date.to_datetime.change(hour: Time.current.hour, min: Time.current.min, sec: Time.current.sec)
    end

    def set_expense
      @expense = Expense.find(params[:id])
    end

    def expense_params
      result = params.require(:expense).permit(:category, :description, :amount, :expense_date)
      if result[:expense_date].present?
        result[:expense_date] = current_time(result[:expense_date])
      else
        result.delete(:expense_date)
      end
      result
    end
  end
end
