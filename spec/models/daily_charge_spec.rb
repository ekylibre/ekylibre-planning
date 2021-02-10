require 'rails_helper'

RSpec.describe DailyCharge, type: :model do
  subject { build(:daily_charge) }

  it "Have a valid factory" do
    expect(subject).to be_valid
  end
end
