class CourierSalaryJob
  include Sidekiq::Job

  def perform
    CourierSalaryCalculatorService.perform_async
  end
end
