load File.expand_path('../capistrano/tasks/deploy.rake', __FILE__)
load File.expand_path('../capistrano/tasks/drupal.rake', __FILE__)
load File.expand_path('../capistrano/tasks/drush.rake', __FILE__)
load File.expand_path('../capistrano/tasks/git.rake', __FILE__)

namespace :load do
  task :defaults do
    load "capistrano/drupal/defaults.rb"
  end
end
