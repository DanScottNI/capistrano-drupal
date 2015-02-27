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
    invoke "git:version_txt"
  end

  task :setup do
    on roles(:app) do
      unless  test("[ -d #{releases_path} ]") ||
              test("[ -d #{shared_path} ]")
        execute :mkdir, "-p #{releases_path} #{shared_path}"
        execute :chown, "-R #{fetch(:user)}:#{fetch(:runner_group)} #{fetch(:deploy_to)}"
      end
      within shared_path do
        fetch(:site_dirs).each do |asset|
          unless test("[ -d #{shared_path}/#{asset} ]")
            execute :mkdir, "#{asset}"
          end
          if test("[ -d #{shared_path}/#{asset} ]")
            execute :chmod, "-R g+rw #{asset}"
            execute :chgrp, "-R www-data #{asset}"
          end
        end
      end
    end
  end

end
