Capistrano::Configuration.instance(:must_exist).load do

  require 'capistrano/recipes/deploy/scm'
  require 'capistrano/recipes/deploy/strategy'
  #require 'capistrano/ext/multistage'
  
  # =========================================================================
  # These variables may be set in the client capfile if their default values
  # are not sufficient.
  # =========================================================================

  set :scm, :git
  set :deploy_via, :remote_cache
  
  _cset(:drush_cmd)     { "drush" }
  _cset(:backup_dest)   { "manual" }
  
  set :runner_group,    "www-data"
  set :group_writable,  false
  
  set :site_dirs,     ['files', 'tmp', 'private']
  set :site_files,    ['settings.php']
  set :shared_dirs,   ['files', 'tmp', 'private']

  # Defaults
  _cset(:deploy_to)   { "/var/www" }
  _cset(:shared_path) { "#{deploy_to}/shared" }
  _cset(:releases_path){ "#{deploy_to}/releases" }
  _cset(:app_path)    {"#{releases_path}/#{release_name}/app"}

  # Set :multisite to true to trigger multisite processing
  _cset(:multisite)   { false }
  _cset(:sites)       { ['default'] }

  after "deploy:update_code", 
        "drupal:stage_settings", 
        "drupal:stage_htaccess", 
        "drupal:symlink_shared", 
        "drush:site_offline", 
        "drush:backupdb", 
        "drush:updatedb", 
        "drush:cache_clear", 
        "drush:site_online"
  after "deploy", "git:push_deploy_tag"
  
  namespace :deploy do
    desc <<-DESC
      Prepares one or more servers for deployment. Before you can use any \
      of the Capistrano deployment tasks with your project, you will need to \
      make sure all of your servers have been prepared with `cap deploy:setup'. When \
      you add a new server to your cluster, you can easily run the setup task \
      on just that server by specifying the HOSTS environment variable:

        $ cap HOSTS=new.server.com deploy:setup

      It is safe to run this task on servers that have already been set up; it \
      will not destroy any deployed revisions or data.
    DESC
    task :setup, :except => { :no_release => true } do
      dirs = [deploy_to, releases_path, shared_path].join(' ')
      run "#{try_sudo} mkdir -p #{releases_path} #{shared_path}"
      run "#{try_sudo} chown -R #{user}:#{runner_group} #{deploy_to}"
      site_dirs.each do |asset|
        run "if [ ! -d \"#{shared_path}/#{asset}\" ] ; then #{try_sudo} mkdir #{shared_path}/#{asset}; fi"
        run "#{try_sudo} chmod -R g+rw #{shared_path}/#{asset}"
        run "#{try_sudo} chgrp -R www-data #{shared_path}/#{asset}"
      end
      # sub_dirs = shared_children.map { |d| File.join(shared_path, d) }
      # run "#{try_sudo} chmod 2775 #{sub_dirs.join(' ')}"
    end
  end
  
  # @TODO finalize permissions
  namespace :drupal do

    desc "Symlink settings and files to shared directory. This allows the settings.php and \
      and files and private directory to be correctly linked to the shared directory on a new deployment."
    task :symlink_shared do

      # Multisite install use sub-folders under :shared_path
      # @TODO untested
      if multisite
        # Iterate over sites folders and pack their contents into the shared directory.
        sites.each do |cdir|
          run "if [ ! -d \"#{shared_path}/#{cdir}\" ] ; then mkdir #{shared_path}/#{cdir}; fi"
          site_dirs.each do |asset|
            run "if [ ! -d \"#{shared_path}/#{cdir}/#{asset}\" ] ; then mkdir #{shared_path}/#{cdir}/#{asset}; fi"
            run "rm -rf #{app_path}/sites/#{cdir}/#{asset} && ln -nfs #{shared_path}/#{cdir}/#{asset} #{app_path}/sites/#{cdir}/#{asset}"
          end
          site_files.each do |config_file|
            run "rm -rf #{app_path}/sites/#{cdir}/#{config_file} && ln -nfs #{shared_path}/#{cdir}/#{config_file} #{app_path}/sites/#{cdir}/#{config_file}"
          end
       end


     ## Single site (standard) installs use :shared_path as the default site folder.
     ## It is not possible to switch from single to multisite without manually
     ## moving directories.
      else
        site_dirs.each do |asset|
          run "if [ ! -d \"#{shared_path}/#{asset}\" ] ; then mkdir #{shared_path}/#{asset}; fi"
          run "rm -rf #{app_path}/sites/default/#{asset} && ln -nfs #{shared_path}/#{asset} #{app_path}/sites/default/#{asset}"
        end
      end
    end

    # use different setting.php files for different stages
    # @TODO use generic settings and insert data from deploy-configs
    desc "Use the stage-specific settings.php #{sites}"
    task :stage_settings do
      sites.each do |site_folder|
        source  = "#{app_path}/sites/#{site_folder}/settings.#{stage_name}.php" 
        dest    = "#{app_path}/sites/#{site_folder}/settings.php"
        run "#{try_sudo}  cp #{source} #{dest}"
      end
    end

    # use different .htaccess files for different stages
    # @TODO use generic settings and insert data from deploy-configs
    desc "Use the stage-specific .htaccess #{sites}"
    task :stage_htaccess do
      source  = "#{app_path}/.htaccess.#{stage_name}" 
      dest    = "#{app_path}/.htaccess"
      run "#{try_sudo}  cp #{source} #{dest}"
    end

  end

  namespace :git do

    desc "Place release tag into Git and push it to origin server."
    task :push_deploy_tag do
      user = `git config --get user.name`
      email = `git config --get user.email`
      tag = "release_#{release_name}"
      if exists?(:stage)
        tag = "#{stage}_#{tag}"
      end
      puts `git tag #{tag} #{revision} -m "Deployed by #{user} <#{email}>"`
      puts `git push origin tag #{tag}`
    end

   end
  
  namespace :drush do

    desc "Backup the database"
    task :backupdb, :on_error => :continue do
      sites.each do |site_folder|
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} bam-backup db #{backup_dest}"
      end
    end

    desc "Run Drupal database migrations if required"
    task :updatedb, :on_error => :continue do
      sites.each do |site_folder|
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} updatedb -y"
      end
    end

    desc "Clear the drupal cache"
    task :cache_clear, :on_error => :continue do
      sites.each do |site_folder|
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} cc all"
      end
    end
    
    desc "Set the site offline"
    task :site_offline, :on_error => :continue do
      sites.each do |site_folder|
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} vset site_offline 1 -y"
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} vset maintenance_mode 1 -y"
      end
    end

    desc "Set the site online"
    task :site_online, :on_error => :continue do
      sites.each do |site_folder|
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} vset site_offline 0 -y"
        run "#{drush_cmd} -r #{app_path}/sites/#{site_folder} vset maintenance_mode 0 -y"
      end
    end

  end
  
end
