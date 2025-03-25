# config valid for current version and patch releases of Capistrano
lock '~> 3.19.2'

set :application, 'strattera'
set :repo_url, 'git@github.com:eldar88e/webapp.git'
set :branch, 'main'
# set :keep_releases, 5 # Default value for keep_releases is 5

server 'strattera.tgapp.online', user: 'deploy', roles: %w[app db worker]

append :linked_files, '.env', 'key.json'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'storage', 'node_modules', 'public/vite'

namespace :deploy do
  desc 'Start Rails inside Docker'
  task :restart do
    on roles(:app) do
      execute "docker compose -f #{fetch(:file)} up --build"
    end
  end

  desc 'Restart Rails inside Docker'
  task :restart_rails do
    on roles(:app) do
      execute "docker exec #{fetch(:docker_app_container)} bin/rails restart"
    end
  end

  desc 'Restart Sidekiq inside Docker'
  task :restart_sidekiq do
    on roles(:worker) do
      # execute "docker exec #{fetch(:docker_sidekiq_container)} pkill -TERM -f sidekiq"
      execute "docker compose -f #{fetch(:file)} restart sidekiq"
    end
  end
end

namespace :rails do
  desc 'Open a Rails console'
  task :console do
    on roles(:app) do
      execute "docker compose -f #{fetch(:file)} exec #{fetch(:docker_app_container)} bundle exec rails c"
    end
  end
end

namespace :docker do
  desc 'List running containers'
  task :ps do
    on roles(:app) do
      execute "docker compose -f #{fetch(:file)} ps"
    end
  end

  desc 'Stats docker containers'
  task :stats do
    on roles(:app) do
      execute 'docker stats'
    end
  end
end

after 'deploy:published', 'deploy:restart_rails'
after 'deploy:published', 'deploy:restart_sidekiq'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
