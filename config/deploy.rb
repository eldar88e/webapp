# ruby config/deploy.rb staging update

require 'sshkit'
require 'sshkit/dsl'
include SSHKit::DSL

SSHKit.config.output_verbosity = :debug

$server = 'deploy@staging.tgapp.online'

SSH_ENV = {
  production: { app_name: 'miniapp', docker_compose_file: 'docker-compose.yml', rails_service: 'miniapp' },
  staging: { app_name: 'miniapp_staging', docker_compose_file: 'docker-compose.staging.yml', rails_service: 's-miniapp' },
  mirena: { app_name: 'webapp_mirena', docker_compose_file: 'docker-compose.mirena.yml', rails_service: 'webapp' }
}.freeze

environment = (ARGV[0] || 'staging').to_sym
config      = SSH_ENV[environment] || SSH_ENV[:staging]

$branch              = 'devise_confirmable'
$app_name            = config[:app_name]
$app_path            = "/home/deploy/#{$app_name}"
$docker_compose_file = config[:docker_compose_file]
$rails_service       = config[:rails_service]

# production mirena staging

def update
  on $server do
    within $app_path do
      execute :git, 'checkout', $branch
      execute :git, 'pull'
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails db:prepare"
      # bundle exec rails assets:precompile TODO: не все изменения применяет vite
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} yarn vite build"
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails restart"
      # TODO: перезагрузка sidekiq
    end
  end
end

def restart
  on $server do
    within $app_path do
      execute :git, 'checkout', $branch
      execute :git, 'pull'
      execute :docker, "compose -f #{$docker_compose_file} up --build #{$rails_service} sidekiq"
    end
  end
end

def rebuild
  on $server do
    within $app_path do
      execute :git, 'pull'
      execute :git, 'checkout', $branch
      execute :git, 'pull'
      execute :docker, "compose -f #{$docker_compose_file} build #{$rails_service} sidekiq"
      execute :docker, "compose -f #{$docker_compose_file} down #{$rails_service} sidekiq base"
      execute :docker, "volume rm #{$app_name}_gems || true"
      execute :docker, "compose -f #{$docker_compose_file} up --build #{$rails_service} sidekiq"
      # execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails db:prepare"
      # execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} yarn vite build"
      # execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails restart"
      # execute :docker, "compose -f #{$docker_compose_file} restart sidekiq"
    end
  end
end

def console
  on $server do
    within $app_path do
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails console"
    end
  end
end

def down
  on $server do
    within $app_path do
      execute :docker, "compose -f #{$docker_compose_file} down"
    end
  end
end

task_name = ARGV[1]

case task_name
when 'update'
  update
when 'restart'
  restart
when 'rebuild'
  rebuild
when 'down'
  down
when 'console'
  console #TODO: не работает
end
