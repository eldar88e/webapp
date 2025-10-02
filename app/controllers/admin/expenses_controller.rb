module Admin
  class ExpensesController < ApplicationController
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
      @expense = Expense.find(params[:id])
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
      @expense = Expense.find(params[:id])
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
      @expense = Expense.find(params[:id])
      @expense.destroy!
      render turbo_stream: [turbo_stream.remove(@expense), success_notice('Расход успешно удален.')]
    end

    private

    def expense_params
      params.require(:expense).permit(:category, :description, :amount, :created_at)
    end
  end
end
