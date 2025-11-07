class PgHeroStatsJob
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 3

  def perform
    PgHero.capture_query_stats
    PgHero.capture_space_stats
  end
end
