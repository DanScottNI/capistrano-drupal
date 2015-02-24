#   # =========================================================================
#   # These variables may be set in the client capfile if their default values
#   # are not sufficient.
#   # =========================================================================


# defaults:
# set   :shared_path,   "#{:deploy_to}/shared"
# set   :releases_path, "#{:deploy_to}/releases"

set   :app_path,      "app"
set   :site_path,     "#{fetch(:app_path)}/sites/default"

set   :drush_cmd,     "drush"
set   :backup_dest,   "manual"

set :site_dirs,     ['files', 'tmp', 'private']

# Dirs that need to remain the same between deploys (shared dirs)
# set :linked_dirs,   ["#{fetch(:app_path)}/sites/default/files", "#{fetch(:app_path)}/sites/default/tmp", "#{fetch(:app_path)}/sites/default/private"]
