require 'mina/bundler'

require 'mina/rails'

require 'mina/git'

require 'mina/rvm'

set :domain, '118.24.14.236'

set :deploy_to, '/opt/backend/cashasst'

set :repository, 'git@github.com:ltl3884/cashasst.git'

set :branch, 'master' 

set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'config/config.yml', 'log', 'shared']

set :user, 'ubuntu'

task :environment do

	queue! %[source ~/.bash_profile && rvm use default]

end

task :setup => :environment do

	queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]

	queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

	queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]

	queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

	queue! %[mkdir -p "#{deploy_to}/#{shared_path}/shared"]

	queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/shared"]

	queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]

	queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]

	queue! %[touch "#{deploy_to}/#{shared_path}/config/config.yml"]

end

	desc "Deploys the current version to the server."

task :deploy => :environment do

	to :before_hook do

	end

	deploy do

		invoke :'git:clone'

		invoke :'deploy:link_shared_paths'

		invoke :'bundle:install'

		invoke :'rails:db_migrate'

    invoke :'rails:assets_precompile'

    invoke :'deploy:cleanup'

    #invoke :start

		to :launch do

			queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"

			queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"

		end

	end

end

desc "start sidekiq"

task :start => :environment do

	invoke :'sidekiq:restart'

end