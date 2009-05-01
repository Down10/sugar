default_run_options[:pty] = true

set :application, "b3s"
set :runner,      "app"
set :user,        "app"

set :scm,                   "git"
set :repository,            "git@github.com:elektronaut/sugar.git"
set :branch,                "b3s"
set :deploy_via,            :remote_cache
set :git_enable_submodules, 1

role :app, "butt3rscotch.org"
role :web, "butt3rscotch.org"
role :db,  "butt3rscotch.org", :primary => true

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/#{application}"

#set :flush_cache, true

desc "Create shared directories"
task :create_shared_dirs, :roles => [:web,:app] do
	run "mkdir #{deploy_to}/#{shared_dir}/cache"
	run "mkdir #{deploy_to}/#{shared_dir}/public_cache"
	run "mkdir #{deploy_to}/#{shared_dir}/sockets"
	run "mkdir #{deploy_to}/#{shared_dir}/sessions"
	run "mkdir #{deploy_to}/#{shared_dir}/index"
	run "mkdir #{deploy_to}/#{shared_dir}/sphinx"
	run "mkdir #{deploy_to}/#{shared_dir}/config"
	run "mkdir #{deploy_to}/#{shared_dir}/config/initializers"
	run "touch #{deploy_to}/#{shared_dir}/config/database.yml"
	run "touch #{deploy_to}/#{shared_dir}/config/initializers/mailer.rb"
end

desc "Fix permissions"
task :fix_permissions, :roles => [:web, :app] do
	run "chmod -R u+x #{deploy_to}/#{current_dir}/script/*"
	run "chmod u+x    #{deploy_to}/#{current_dir}/public/dispatch.*"
	run "chmod u+rwx  #{deploy_to}/#{current_dir}/public"
end

desc "Create symlinks"
task :create_symlinks, :roles => [:web,:app] do
	run "ln -s #{deploy_to}/#{shared_dir}/cache #{deploy_to}/#{current_dir}/tmp/cache"
	run "ln -s #{deploy_to}/#{shared_dir}/sockets #{deploy_to}/#{current_dir}/tmp/sockets"
	run "ln -s #{deploy_to}/#{shared_dir}/sessions #{deploy_to}/#{current_dir}/tmp/sessions"
	run "ln -s #{deploy_to}/#{shared_dir}/index #{deploy_to}/#{current_dir}/index"
	run "ln -s #{deploy_to}/#{shared_dir}/public_cache #{deploy_to}/#{current_dir}/public/cache"
	run "ln -s #{deploy_to}/#{shared_dir}/doodles #{deploy_to}/#{current_dir}/public/doodles"
	run "ln -s #{deploy_to}/#{shared_dir}/sphinx #{deploy_to}/#{current_dir}/db/sphinx"

	run "ln -s #{deploy_to}/#{shared_dir}/config/database.yml #{deploy_to}/#{current_dir}/config/database.yml"
	run "ln -s #{deploy_to}/#{shared_dir}/config/session_key #{deploy_to}/#{current_dir}/config/session_key"
	run "ln -s #{deploy_to}/#{shared_dir}/config/initializers/mailer.rb #{deploy_to}/#{current_dir}/config/initializers/mailer.rb"
end

namespace :deploy do
    namespace :web do
        desc "Present a maintenance page to visitors. Message is customizable with the REASON enviroment variable."
        task :disable, :roles => [:web, :app] do
            if reason = ENV['REASON']
                run("cd #{deploy_to}/current; /usr/bin/rake sugar:disable_web REASON=\"#{reason}\"")
            else
                run("cd #{deploy_to}/current; /usr/bin/rake sugar:disable_web")
            end
        end
        
        desc "Makes the application web-accessible again."
        task :enable, :roles => [:web, :app] do
            run("cd #{deploy_to}/current; /usr/bin/rake sugar:enable_web")
        end
    end

	desc "Restart Application"
	task :restart, :roles => :app do
		run "touch #{current_path}/tmp/restart.txt"
	end
end

after "deploy:setup", :create_shared_dirs
after "deploy:symlink", :fix_permissions
after "deploy:symlink", :create_symlinks


