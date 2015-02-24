 namespace :git do

  desc "Place release tag into Git and push it to origin server."
  task :push_deploy_tag do
    on roles(:app) do
      user = `git config --get user.name`
      email = `git config --get user.email`

      remote = fetch(:remote, "origin")
      stage  = fetch(:stage)
      branch = fetch(:branch)

      date = Time.now
      tagname = "v3-#{stage}-#{date.strftime("%Y-%m-%d")}"

      # Delete all tags for respective stage.
      oldtags = `git tag -l '#{stage}-*'`.split("\n")
      oldtags.each { |tag| `git tag -d #{tag}` }

      # Push all the changes.
      `git push --tags #{remote} :#{oldtags.join(' :')}`

      # Tag HEAD of respective branch.
      `git tag -a #{tagname} -m "Deployment of #{stage} at #{date.to_s} by #{user} (#{email})" #{branch}`
      `git push --tags #{remote} +#{tagname}`
    end
  end

end
