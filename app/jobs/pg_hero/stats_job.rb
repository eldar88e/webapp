module PgHero
  class StatsJob
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform
      PgHero.capture_query_stats if Rails.env.production?
    end
  end
end
