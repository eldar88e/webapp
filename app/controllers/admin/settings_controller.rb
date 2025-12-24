module Admin
  class SettingsController < Admin::ApplicationController
    include Admin::ResourceConcerns

    def index
      @q_settings      = Setting.order(:created_at).ransack(params[:q])
      @pagy, @settings = pagy(@q_settings.result)
    end

    private

    def setting_params
      params.expect(setting: %i[variable value description])
    end
  end
end
