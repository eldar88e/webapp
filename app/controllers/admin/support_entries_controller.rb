module Admin
  class SupportEntriesController < ApplicationController
    include Admin::ResourceConcerns

    def index
      @pagy, @resources = pagy SupportEntry.order(:question)
    end

    private

    def support_entry_params
      params.expect(support_entry: %i[question answer])
    end
  end
end
