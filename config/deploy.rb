# ruby config/deploy.rb update

require 'sshkit'
require 'sshkit/dsl'
include SSHKit::DSL

SSHKit.config.output_verbosity = :debug

$server = 'deploy@staging.tgapp.online'

$app_name = 'miniapp_staging'
$app_path = "/home/deploy/#{$app_name}"
$docker_compose_file = 'docker-compose.staging.yml'
$rails_service = 's-miniapp'

# production mirena staging

def update
  on $server do
    within $app_path do
      execute :git, 'pull'
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails db:prepare"
      # bundle exec rails assets:precompile
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} yarn vite build"
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails restart"
    end
  end
end

def restart
  on $server do
    within $app_path do
      execute :docker, "compose -f #{$docker_compose_file} up --build #{$rails_service} sidekiq"
    end
  end
end

def rebuild
  on $server do
    within $app_path do
      execute :docker, "compose -f #{$docker_compose_file} down #{$rails_service} sidekiq"
      execute :docker, "volume rm #{$app_name}_gems"
      execute :docker, "compose -f #{$docker_compose_file} up --build #{$rails_service} sidekiq"
    end
  end
end

task_name = ARGV[0]

case task_name
when 'update'
  update
when 'restart'
  restart
when 'rebuild'
  rebuild
end
