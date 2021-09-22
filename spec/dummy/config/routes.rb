# frozen_string_literal: true

Rails.application.routes.draw do
  mount Planning::Engine => '/planning'
  namespace :backend do
    resources :load_plans
    namespace :load_plans do
      get :period_charges
    end
  end
end
