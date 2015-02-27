 namespace :git do

  desc "Place release tag into Git and push it to origin server."
  task :push_deploy_tag do
    on roles(:app) do
      within repo_path do
        set(:current_revision, capture(:git, "log -1 --format=%H"))
      end
      within release_path do
        # release path may be resolved already or not
        resolved_release_path = capture(:pwd, "-P")
        set(:release_name, resolved_release_path.split('/').last)
      end
    end

    run_locally do
      user = capture(:git, "config --get user.name")
      email = capture(:git, "config --get user.email")
      remote = fetch(:remote, "origin")
      stage  = fetch(:stage)
      branch = fetch(:branch)
      date = Time.now.strftime("%Y-%m-%d")

      tag_msg = "Deployed by #{user} <#{email}> to #{fetch :stage} as #{fetch :release_name}"
      tag_name = "#{stage}-#{fetch(:app_version)}-#{date.to_s}-#{fetch :release_name}"

      # Delete all tags for respective stage.
      oldtags = capture(:git, "tag -l '#{stage}*'").split("\n")

      unless oldtags.empty?
        oldtags.each { |tag| capture(:git, "tag -d #{tag}") }
        # Push all the changes.
        execute :git, %(push --tags #{remote} :#{oldtags.join(' :')})
      end

      # Tag HEAD of respective branch.
      execute :git, %(tag -a #{tag_name} #{fetch :current_revision} -m "#{tag_msg}")
      execute :git, "push --tags #{remote}"
    end
  end

  desc "Write version txt-file"
  task :version_txt do
    on roles(:app) do
      within repo_path do
        set(:current_revision, capture(:git, "log -1 --format=%H"))
      end
      within current_path.join(fetch(:site_path)) do
        # set version
        execute :echo, "\"VERSION #{fetch(:app_version)}_rev_#{fetch(:current_revision)[0..8]} #{DateTime.now.to_s}\" > version.txt"
      end
    end
  end

end
