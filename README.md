# Ekylibre Planning

This sub-project uses MIT-LICENSE. <br>

## Installation (from version 1.0)

Add the gem in your ekylibre gemfile :
```
  gem 'ekylibre-planning', git: 'git@gitlab.com:ekylibre/ekylibre-planning.git'
  gem 'vuejs-rails'
```
or in development mode, you can clone the repository in 'planning' folder near ekylibre and then add in your ekylibre gemfile :
```
  gem 'ekylibre-planning', path: '../ekylibre-planning'
  gem 'vuejs-rails'
```

## Routes, Navigation , Controllers & Views

Routes, navigation and rights relatives to this plugins is in config folder

Controllers and Views is in app/views and app/controllers folders

## Models, Services, API

This elements are manage by Ekylibre Core. If you need some improvement, you have to fork or open a branch in ekylibre core project.

## Testing :

To test they are a fake app (thank's to rails) in 'test/dummy'. <br>
So if they are some model require in the app, we can add it in the dummy app ! <br>
They are some good information here : https://kyrofa.com/posts/rails-writing-engine-tests-that-depend-on-main-application-models

<br>

To run the test run `rspec`.
