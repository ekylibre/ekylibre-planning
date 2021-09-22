# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'planning/scenarios/show', type: :view do
  before(:each) do
    @planning_scenario = assign(:planning_scenario, Planning::Scenario.create!)
  end

  it 'renders attributes in <p>' do
    render
  end
end
