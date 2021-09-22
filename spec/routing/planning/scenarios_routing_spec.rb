# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Planning::ScenariosController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/planning/scenarios').to route_to('planning/scenarios#index')
    end

    it 'routes to #new' do
      expect(get: '/planning/scenarios/new').to route_to('planning/scenarios#new')
    end

    it 'routes to #show' do
      expect(get: '/planning/scenarios/1').to route_to('planning/scenarios#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/planning/scenarios/1/edit').to route_to('planning/scenarios#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/planning/scenarios').to route_to('planning/scenarios#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/planning/scenarios/1').to route_to('planning/scenarios#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/planning/scenarios/1').to route_to('planning/scenarios#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/planning/scenarios/1').to route_to('planning/scenarios#destroy', id: '1')
    end
  end
end
