require_relative 'docker/docker'

if Capistrano::Configuration.instance
  Docker::Capistrano.load_into(Capistrano::Configuration.instance)
end
