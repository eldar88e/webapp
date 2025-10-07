module Admin
  module ResourceConcerns
    extend ActiveSupport::Concern

    included do
      before_action :set_resource, if: :resource_action?
    end

    def new
      @resource = resource_class.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, "Добавить #{resource_name.downcase}"),
        turbo_stream.update(:modal_body, partial: form_partial, locals: { method: :post })
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, "Редактировать #{resource_name.downcase}"),
        turbo_stream.update(:modal_body, partial: form_partial, locals: { method: :patch })
      ]
    end

    def create
      @resource = resource_class.new(resource_params)
      if @resource.save
        render turbo_stream: [
          turbo_stream.prepend(:resources, partial: resource_partial, locals: { resource: @resource }),
          success_notice(t('.create'))
        ]
      else
        error_notice @resource.errors.full_messages
      end
    end

    def update
      if @resource.update(resource_params)
        render turbo_stream: [
          turbo_stream.replace(@resource, partial: resource_partial, locals: { resource: @resource }),
          success_notice(t('.update'))
        ]
      else
        error_notice @resource.errors.full_messages
      end
    end

    def destroy
      @resource.destroy!
      render turbo_stream: [turbo_stream.remove(@resource), success_notice(t('.destroy'))]
    end

    private

    def set_resource
      @resource = resource_class.find(params[:id])
    end

    def resource_class
      controller_name.singularize.classify.constantize
    end

    def form_partial
      "/#{controller_path}/form"
    end

    def resource_partial
      "/#{controller_path}/#{resource_class.model_name.param_key}"
    end

    def resource_name
      resource_class.model_name.human
    end

    def resource_action?
      %w[show edit update destroy].include?(action_name)
    end

    def resource_params
      send "#{resource_class.model_name.param_key}_params"
    end
  end
end
