set :application, 'yeloapp'
set :repo_url, 'git@bitbucket.org:yelo/yeloapp.git'
#set :repo_url, 'git@bitbucket.org:suras/yeloapp.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

 set :deploy_to, '/home/deploy/yelo'

 set :pty,  false
 
 set :rvm1_ruby_version, "2.1.2"

 set :sidekiq_config, "#{current_path}/config/sidekiq.yml"
 set :sidekiq_env, "development"


# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

# set :linked_files, %w{config/database.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
 set :linked_dirs, %w{log tmp/backup tmp/pids tmp/cache tmp/sockets vendor/bundle}
 set :linked_dirs, fetch(:linked_dirs) + %w{public/system public/uploads}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
       within release_path do
        # execute :rake, 'cache:clear'
      end
    end
  end

  after :finishing, 'deploy:cleanup'

end