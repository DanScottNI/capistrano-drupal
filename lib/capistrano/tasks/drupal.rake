 # @TODO finalize permissions
  namespace :drupal do

    desc "Symlink settings and files to shared directory. This allows the settings.php and \
      and files and private directory to be correctly linked to the shared directory on a new deployment."
    task :symlink_shared do
      on roles(:app) do
        within release_path.join(fetch(:site_path)) do
          fetch(:site_dirs).each do |asset|
            execute "if [ ! -d \"#{shared_path}/#{asset}\" ] ; then mkdir #{shared_path}/#{asset}; fi"
            execute :rm, "-rf #{asset} && ln -nfs #{shared_path}/#{asset} #{asset}"
          end
        end
      end
    end

    # use different setting.php files for different stages
    # @TODO use generic settings and insert data from deploy-configs
    desc "Use the stage-specific settings.php"
    task :stage_settings do
      on roles(:app) do
        within release_path.join(fetch(:site_path)) do
          source  = "settings.#{fetch(:stage_name)}.php"
          dest    = "settings.php"
          execute :cp, "#{source}", "#{dest}"
        end
      end
    end

    # use different .htaccess files for different stages
    # @TODO use generic settings and insert data from deploy-configs
    desc "Use the stage-specific .htaccess"
    task :stage_htaccess do
      on roles(:app) do
        within release_path.join(fetch(:app_path)) do
          source  = ".htaccess.#{fetch(:stage_name)}"
          dest    = ".htaccess"
          execute :cp, "#{source}", "#{dest}"
        end
      end
    end
  end
