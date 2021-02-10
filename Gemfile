source 'https://rubygems.org'

# Declare your gem's dependencies in planning.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

ruby '>= 2.6.6', '< 3.0.0'

gem 'vuejs-rails'

gem 'pg', '~> 1.0' # Needed for some tasks

gem 'coffee-rails', '~> 4.1'

gem 'simple_form', '~> 3.4'

gem 'lodash-rails'

gem 'jbuilder', '~> 2.0'

group :development, :test do
  gem 'pry-byebug'
end

group :test do
  gem 'rspec-rails'
  gem 'factory_bot'
  # See https://github.com/rails/execjs#readme for more supported runtimes
  gem 'therubyracer', platforms: :ruby
  gem 'faker'
  gem 'byebug'
  gem 'guard-rspec'
  gem "haml-rails", ">= 1.0"

  gem 'code_string', '>= 0.0.1'
end


# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]
