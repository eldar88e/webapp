module Admin
  class ErrorsController < ApplicationController
    before_action :set_service, :set_items
    before_action :errors, only: :show

    def index; end

    def show
      @item  = @items.find { |i| i['id'].to_s == params[:id] }
      @error = params['item'].present? ? @errors.find { |i| i['id'] == params['item'].to_i } : @errors.first
    end

    private

    def set_service
      @service = Admin::RollbarService.new
    end

    def set_items
      @items = Rails.cache.fetch(:error_items, expires_in: 10.minutes) { @service.items }
    end

    def errors
      @errors ||= Rails.cache.fetch("errors_#{params[:id]}", expires_in: 5.minutes) { @service.instances(params[:id]) }
    end
  end
end
