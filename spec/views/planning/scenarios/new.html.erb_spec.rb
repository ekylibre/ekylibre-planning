require 'rails_helper'

RSpec.describe "planning/scenarios/new", type: :view do
  before(:each) do
    assign(:planning_scenario, Planning::Scenario.new())
  end

  it "renders new planning_scenario form" do
    render

    assert_select "form[action=?][method=?]", planning_scenarios_path, "post" do
    end
  end
end
