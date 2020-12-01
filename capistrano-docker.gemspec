lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'capistrano/docker/version'

Gem::Specification.new do |spec|
  spec.name        = 'capistrano-docker'
  spec.version     = Capistrano::Docker::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['Jürgen Walter', 'Daniel Temme']
  spec.email       = %w[juwalter@gmail.com dtemme@gmail.com]
  spec.homepage    = 'https://github.com/juwalter/capistrano-docker'
  spec.summary     = 'Integrates capistrano with docker.io'
  spec.description = 'Integrates capistrano with docker.io'
  spec.license     = 'MIT'

  spec.add_dependency 'capistrano', '~> 3.0'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'bundler', '~> 2.1'

  spec.require_paths = %w[lib]
  spec.files        = %w[
    LICENSE
    README.md
    Changelog.md
    lib/capistrano/docker.rb
    lib/capistrano/docker/version.rb
    lib/capistrano/docker/docker.rb
  ]
end
