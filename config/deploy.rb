require 'sshkit'
require 'sshkit/dsl'
include SSHKit::DSL

SSHKit.config.output_verbosity = :debug

# Объявляем глобальные переменные (с префиксом `$`)
$server = 'deploy@staging.tgapp.online'
$app_path = '/home/deploy/miniapp_staging'
$docker_compose_file = 'docker-compose.staging.yml'
$rails_service = 's-miniapp'

def update
  on $server do
    within $app_path do
      execute :git, 'pull'
      execute :docker, "compose -f #{$docker_compose_file} exec #{$rails_service} bundle exec rails restart"
    end
  end
end

def restart_server
  on $server do
    within $app_path do
      execute :docker, "compose -f #{$docker_compose_file} up --build #{$rails_service} sidekiq"
    end
  end
end

task_name = ARGV[0]

case task_name
when 'update'
  update
when 'restart_server'
  restart_server
end
