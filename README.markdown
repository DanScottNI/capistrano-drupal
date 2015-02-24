# Capistrano Drupal

This gem provides a number of tasks which are useful for deploying Drupal projects. 

## Installation
These gems must be installed on your system first.

* capistrano
* rubygems

You can check to see a list of installed gems by running this.

    $ gem query --local

If any of these gems is missing you can install them with:

    $ gem install gemname

Finally install the capistrano-drupal recipes as a gem.
    # gem install capistrano-drupal
    

### Building

This project uses [Jeweler](https://github.com/technicalpickles/jeweler) (`gem install jeweler`) to build and install the gem.

    $ cd {capistrano-drupal-DIRECTORY}
    $ rake install

Not using Jeweler you can build capistrano-drupal like this:

    $ cd {capistrano-drupal-DIRECTORY}
    $ gem build capistrano-drupal.gemspec
    # gem install capistrano-drupal-{VERSION}.gem


## Usage

Open your applications base directory and create a capfile like this:

    $ capify

Open your application's `Capfile` and make it begin like this:

    # Load DSL and Setup Up Stages
    require 'capistrano/setup'
    
    require 'capistrano-drupal'

You should then be able to proceed as you would usually, you may want to familiarise yourself with the truncated list of tasks, you can get a full list with:

    $ cap -T


## App-migration to Capistrano 3

#### Capfile 

needs only one require `require 'capistrano-drupal'`

#### deploy.rb 

only needs 

    set :application, 'drupal-x'
    set :repo_url,    'ssh://x.git'
    set :user,        'x'

#### stage-settings (i.e. production.rb)

role syntax changed

    role :app, %w{x}
    role :web, %w{x}
    role :db,  %w{x}

server syntax added

    server 'x.org', user: fetch(:user), roles: %w{web app}, my_property: :my_value
