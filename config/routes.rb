# frozen_string_literal: true

Rails.application.routes.draw do
  concern :list do
    get :list, on: :collection
  end

  concern :unroll do
    get :unroll, on: :collection
  end

  concern :incorporate do
    collection do
      get :pick
      post :incorporate
    end
  end

  namespace :backend do
    namespace :cells do
      resource :planning_charges_by_activity_cell, only: :show
      resource :planning_charges_by_nature_tool_cell, only: :show
      resource :planning_charges_by_nature_input_cell, only: :show
    end
  end

  namespace :planning do
    resources :dashboards, only: [] do
      collection do
        get :planning
      end
    end

    resources :interventions do
      resources :product_planning, only: [] do
        member do
          get :is_planned_intervention
        end
      end
    end

    resources :intervention_templates, concerns: :list do
      collection do
        get :select_type
        get :templates_of_activity
        get :interventions_have_activities
      end

      member do
        get :duplication_list
        get :list_technical_itineraries
        get :duplicate
        post :duplicate_intervention_templates
      end
    end

    resources :load_plans do
      collection do
        get :period_charges
        get :period_charges_details
      end
    end

    resources :schedulings do
      collection do
        get :available_time_or_quantity
        get :change_week_preference
        get :intervention_chronologies
        get :new_detailed_intervention
        get :new_intervention
        get :update_modal_time
        get :weekly_daily_charges

        put :update_proposal

        post :create_intervention
      end

      member do
        post :update_estimated_date
        post :update_intervention_dates
      end
    end

    resources :technical_itineraries, concerns: %i[incorporate list unroll] do
      collection do
        post :duplicate_intervention
      end

      member do
        get :list_intervention_templates
        get :list_activity_productions
        get :duplicate
      end
    end

    resources :scenarios, concerns: :list do
      get :chart
      member do
        get :list_rotations
      end
      collection do
        get :period_charges
      end
    end
  end
end
