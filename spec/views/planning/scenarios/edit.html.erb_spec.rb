# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'planning/scenarios/edit', type: :view do
  before(:each) do
    @planning_scenario = assign(:planning_scenario, Planning::Scenario.create!)
  end

  it 'renders the edit planning_scenario form' do
    render

    assert_select 'form[action=?][method=?]', planning_scenario_path(@planning_scenario), 'post' do
    end
  end
end
