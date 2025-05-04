module Admin
  class SupportController < ApplicationController
    def index
      @questions = SupportEntry.order(:question)
    end

    def new
      @questions = SupportEntry.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить вопрос'),
        turbo_stream.update(:modal_body, partial: '/admin/settings/form', locals: { method: :post })
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать настройку'),
        turbo_stream.update(:modal_body, partial: '/admin/settings/form', locals: { method: :patch })
      ]
    end

    def create
      @setting = Setting.new(setting_params)

      if @setting.save
        redirect_to admin_settings_path, notice: t('.create')
      else
        error_notice(@setting.errors.full_messages, :unprocessable_entity)
      end
    end

    def update
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: t('.update')
      else
        error_notice(@setting.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @setting.destroy!
      redirect_to admin_settings_path, status: :see_other, notice: t('.destroy')
    end

    private

    def set_setting
      @setting = Setting.find(params[:id])
    end

    def setting_params
      params.require(:setting).permit(:variable, :value, :description)
    end
  end
end
