require 'lodash-rails'

module Planning
  class Engine < ::Rails::Engine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
    end

    initializer 'planning.assets.precompile' do |app|
      app.config.assets.precompile += %w( planning.css planning.js )
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Planning::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :extend_navigation do |_app|
      Planning::ExtNavigation.add_navigation_xml_to_existing_tree
    end
  end
end
