#   before "deploy",
#         "drush:site_offline",
#         "drush:backupdb"
#   after "deploy:update_code",
#         "drupal:stage_settings",
#         "drupal:stage_htaccess",
#         "drupal:symlink_shared"
#   after "deploy",
#         "drush:updatedb",
#         "drush:cache_clear",
#         "drush:site_online"
#   after "deploy", "git:push_deploy_tag"
#
load File.expand_path('../capistrano/tasks/deploy.rake', __FILE__)
load File.expand_path('../capistrano/tasks/drupal.rake', __FILE__)
load File.expand_path('../capistrano/tasks/drush.rake', __FILE__)
load File.expand_path('../capistrano/tasks/git.rake', __FILE__)

namespace :load do
  task :defaults do
    load "capistrano/drupal/defaults.rb"
  end
end
