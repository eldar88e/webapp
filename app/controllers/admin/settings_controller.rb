module Admin
  class SettingsController < Admin::ApplicationController
    before_action :set_setting, only: %i[edit update destroy]

    def index
      @q_settings      = Setting.order(:created_at).ransack(params[:q])
      @pagy, @settings = pagy(@q_settings.result)
    end

    def new
      @setting = Setting.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить настройку'),
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
        redirect_to admin_settings_path, notice: t('controller.settings.create')
      else
        error_notice(@setting.errors.full_messages, :unprocessable_entity)
      end
    end

    def update
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: t('controller.settings.update')
      else
        error_notice(@setting.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @setting.destroy!
      redirect_to admin_settings_path, status: :see_other, notice: t('controller.settings.destroy')
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
