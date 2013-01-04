require 'rvm/capistrano' # Для работы rvm
require 'bundler/capistrano' # Для работы bundler. При изменении гемов bundler автоматически обновит все гемы на сервере, чтобы они в точности соответствовали гемам разработчика. 

set :application, "JukeboxOnRails"
set :rails_env, "production"
set :domain, "deployer@de1mos.net"
set :deploy_to, "/var/www/#{application}"
set :use_sudo, false
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"
set :thin_conf, "#{deploy_to}/current/config/thin.yml"
set :thin_pid, "#{deploy_to}/shared/pids/thin.pid"

set :rvm_ruby_string, 'ruby-1.9.3' # Это указание на то, какой Ruby интерпретатор мы будем использовать.

set :scm, :git # Используем git. Можно, конечно, использовать что-нибудь другое - svn, например, но общая рекомендация для всех кто не использует git - используйте git. 
set :repository,  "git://github.com/de1mos242/JukeboxOnRails.git"
set :branch, "master" # Ветка из которой будем тянуть код для деплоя.
set :deploy_via, :remote_cache # Указание на то, что стоит хранить кеш репозитария локально и с каждым деплоем лишь подтягивать произведенные изменения. Очень актуально для больших и тяжелых репозитариев.

role :web, domain
role :app, domain
role :db,  domain, :primary => true

before 'deploy:setup', 'rvm:install_rvm', 'rvm:install_ruby' # интеграция rvm с capistrano настолько хороша, что при выполнении cap deploy:setup установит себя и указанный в rvm_ruby_string руби.

after 'deploy:setup', :roles => :app do
	run "mkdir -p #{deploy_to}/shared/config"
end

after 'deploy:update_code', :roles => :app do
  # Здесь для примера вставлен только один конфиг с приватными данными - database.yml. Обычно для таких вещей создают папку /srv/myapp/shared/config и кладут файлы туда. При каждом деплое создаются ссылки на них в нужные места приложения.
  store_configs = {}
  store_configs["database.yml"] = "/config/database.yml"
  store_configs["shoutcast.yml"] = "/config/audio/shoutcast.yml"
  store_configs["speakers.yml"] = "/config/audio/speakers.yml"
  store_configs["common.yml"] = "/config/audio/common.yml"
  store_configs["vk.yml"] = "/config/audio_providers/vk.yml"
  store_configs.each do |config_filename, destination|
  	run "rm -f #{current_release}#{destination}"
  	run "ln -s #{deploy_to}/shared/config/#{config_filename} #{current_release}#{destination}"
  end
end

namespace :deploy do
  task :restart do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D; fi"
    run "cd #{deploy_to}/current && bundle exec thin restart -C #{thin_conf}"
  end
  task :start do
    run "cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D"
    run "cd #{deploy_to}/current && bundle exec thin start -C #{thin_conf}"
  end
  task :stop do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
    run "cd #{deploy_to}/current && bundle exec thin stop -C #{thin_conf}"
  end
end