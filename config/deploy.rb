require 'bundler/capistrano'

set :application, "drug"
set :repository, "git://github.com/drugpl/drug-site.git"
set :deploy_to, "/srv/#{application}"
set :user, "#{application}"
set :scm, :git
set :bundle_without, %w(test development)
set :ssh_options, {:forward_agent => true}
set :keep_releases, 5
set :use_sudo, false
set :unicorn_binary, "unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

server "drug", :app, :web, :db, :primary => true

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && #{try_sudo} bundle exec #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
  end

  task :stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end

  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end

  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end

  task :link_configuration_files do
    %w(unicorn.rb database.yml).each do |file|
      run "if [ -f #{deploy_to}/shared/#{file} ] ; then ln -sf #{deploy_to}/shared/#{file} #{latest_release}/config/; fi"
    end
  end

  task :link_secret_token do
    run "if [ -f #{deploy_to}/shared/secret_token.rb ] ; then ln -sf #{deploy_to}/shared/secret_token.rb #{latest_release}/config/initializers/; fi"
  end
end

after "deploy:finalize_update", "deploy:link_configuration_files"
after "deploy:finalize_update", "deploy:link_secret_token"
after "deploy:finalize_update", "deploy:migrate"
after "deploy:restart",         "deploy:cleanup"
