class SupportsController < ApplicationController
  def index
    @questions = SupportEntry.order(:question)
  end
end
