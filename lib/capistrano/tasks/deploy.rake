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


  task  :updated do
    invoke "drush:prev_release_offline"
    invoke "drush:backupdb"
    invoke "drupal:stage_settings"
    invoke "drupal:stage_htaccess"
    invoke "drupal:symlink_shared"
  end
  task  :publishing do
    invoke "drush:updatedb"
    invoke "drush:cache_clear"
  end
  task  :finished do
    invoke "drush:site_online"
    invoke "git:push_deploy_tag"
  end

  task :setup do
    on roles(:app) do
      dirs = [fetch(:deploy_to), fetch(:releases_path), fetch(:shared_path)].join(' ')
      execute :mkdir, "-p #{fetch(:releases_path)} #{fetch(:shared_path)}"
      execute :chown, "-R #{fetch(:user)}:#{fetch(:runner_group)} #{fetch(:deploy_to)}"
      fetch(:site_dirs).each do |asset|
        test "if[ ! -d \"#{fetch(:shared_path)}/#{asset}\" ] ; then mkdir #{fetch(:shared_path)}/#{asset}; fi"
        execute :chmod, "-R g+rw #{fetch(:shared_path)}/#{asset}"
        execute :chgrp, "-R www-data #{fetch(:shared_path)}/#{asset}"
      end
      # sub_dirs = shared_children.map { |d| File.join(fetch(:shared_path), d) }
      # run "chmod 2775 #{sub_dirs.join(' ')}"
    end
  end
end
