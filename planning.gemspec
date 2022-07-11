# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'planning/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'planning'
  s.version     = Planning::VERSION
  s.authors     = ['Ekylibre']
  s.email       = ['dev@ekylibre.com']
  s.homepage    = 'https://ekylibre.com'
  s.summary     = 'Planning gem for ekylibre'
  s.description = 'Planning gem for ekylibre'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'coffee-rails'
  s.add_dependency 'jbuilder'
  s.add_dependency 'lodash-rails'
  s.add_dependency 'onoma'
  s.add_dependency 'rails', '~> 5.0.7.2'
  s.add_dependency 'sassc-rails', '~> 2.0'
  s.add_dependency 'vuejs-rails'

  # s.add_development_dependency "sqlite3"
  s.add_dependency 'factory_bot'
end
