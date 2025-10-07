class CourierSalaryJob
  include Sidekiq::Job

  def perform
    CourierSalaryCalculatorService.call
  end
end
