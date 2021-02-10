require 'rails_helper'

RSpec.describe TechnicalItinerary, type: :model do
  subject do
    build(:technical_itinerary)
  end

  it "Have a valid factory" do
    expect(subject).to be_valid
  end

  describe 'Test errors' do
    describe 'name errors' do
      subject { build(:technical_itinerary, name: name)}
      let(:name) { nil }

      it "Have an error message" do
        subject.valid?
        expect(subject.errors[:name]).to include("can't be blank")
      end
    end

    describe 'campaign errors' do
      subject { build(:technical_itinerary, campaign_id: campaign_id)}
      let(:campaign_id) { nil }

      it "Have an error message" do
        subject.valid?
        expect(subject.errors[:campaign_id]).to include("can't be blank")
      end
      describe 'Error on change campaign' do
        subject { create(:technical_itinerary)}
        it ' Have an error message' do
          itinerary = subject
          campaign = create(:campaign)
          itinerary.update(campaign: campaign)
          expect(itinerary.errors[:campaign]).to include("change_not_allowed")
        end
      end
    end
  end
end
