module Admin
  class SettingsController < Admin::ApplicationController
    before_action :set_setting, only: %i[edit update destroy]

    def index
      @settings = Setting.all.order(:created_at)
    end

    def new
      @setting = Setting.new
    end

    def create
      @setting = Setting.new(setting_params)

      if @setting.save
        redirect_to admin_settings_path, notice: 'Setting was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: 'Setting was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @setting.destroy!
      redirect_to admin_settings_path, status: :see_other, notice: 'Setting was successfully destroyed.'
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
