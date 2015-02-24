
namespace :drush do
  desc "Backup the database"
  task :backupdb do
    on roles(:app) do
      last_release_path = last_release_path(releases_path, current_path)
      within last_release_path.join(fetch(:site_path)) do
        execute "#{fetch(:drush_cmd)}".to_sym, "bam-backup db #{fetch(:backup_dest)}"
      end
    end
  end

  desc "Run Drupal database migrations if required"
  task :updatedb do
    on roles(:app) do
      within current_path.join(fetch(:site_path)) do
        execute "#{fetch(:drush_cmd)}".to_sym, "updatedb -y"
      end
    end
  end

  desc "Clear the drupal cache"
  task :cache_clear do
    on roles(:app) do
      within current_path.join(fetch(:site_path)) do
        execute "#{fetch(:drush_cmd)}".to_sym, "cc all"
      end
    end
  end

  desc "Set previous release offline"
  task :prev_release_offline do
    on roles(:app) do
      last_release_path = releases_path.join(capture(:ls, '-xt', releases_path).split[1])
      within last_release_path.join(fetch(:site_path)) do
        execute "#{fetch(:drush_cmd)}".to_sym, "vset site_offline 1 -y"
      end
    end
  end

  desc "Set the current site offline"
  task :site_offline do
    on roles(:app) do
      within current_path.join(fetch(:site_path)) do
        execute "#{fetch(:drush_cmd)}".to_sym, "vset site_offline 1 -y"
        execute "#{fetch(:drush_cmd)}".to_sym, "vset maintenance_mode 1 -y"
      end
    end
  end

  desc "Set the site online"
  task :site_online do
    on roles(:app) do
      last_release_path = releases_path.join(capture(:ls, '-xt', releases_path).split[0])
      within last_release_path.join(fetch(:site_path)) do
        execute "#{fetch(:drush_cmd)}".to_sym, "vset site_offline 0 -y"
        execute "#{fetch(:drush_cmd)}".to_sym, "vset maintenance_mode 0 -y"
      end
    end
  end

end

def last_release_path(releases_path, current_path)
  last_release_path = releases_path.join(capture(:ls, '-xt', releases_path).split[1])
  if test "[ `readlink #{current_path}` != #{last_release_path} ]"
    return last_release_path
  end
  error 'Last release is the current release, returning current path...'
  return current_path

end
