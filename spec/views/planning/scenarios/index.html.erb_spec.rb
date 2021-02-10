require 'rails_helper'

RSpec.describe "planning/scenarios/index", type: :view do
  before(:each) do
    assign(:planning_scenarios, [
      Planning::Scenario.create!(),
      Planning::Scenario.create!()
    ])
  end

  it "renders a list of planning/scenarios" do
    render
  end
end
