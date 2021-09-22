# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InterventionTemplate, type: :model do
  subject do
    build(:intervention_template)
  end

  it 'Have a valid factory' do
    expect(subject).to be_valid
  end

  describe 'Test errors' do
    describe 'name errors' do
      subject { build(:intervention_template, name: name) }
      let(:name) { nil }

      it 'Have an error message' do
        subject.valid?
        expect(subject.errors[:name]).to include("can't be blank")
      end
    end

    describe 'Procedure errors' do
      subject { build(:intervention_template, procedure_name: procedure_name) }
      let(:procedure_name) { nil }
      it 'Have an error message' do
        subject.valid?
        expect(subject.errors[:procedure_name]).to include("can't be blank")
      end
    end

    describe 'Workflow errors' do
      subject { build(:intervention_template, workflow: workflow) }
      let(:workflow) { nil }
      it 'Have an error message' do
        subject.valid?
        expect(subject.errors[:workflow]).to include("can't be blank")
      end
    end

    describe 'Campaign errors' do
      subject { build(:intervention_template, campaign: campaign) }
      let(:campaign) { nil }
      it 'Have an error message' do
        subject.valid?
        expect(subject.errors[:campaign]).to include("can't be blank")
      end

      describe 'Error on change campaign' do
        subject { create(:intervention_template) }
        it ' Have an error message' do
          template = subject
          campaign = create(:campaign)
          template.update(campaign: campaign)
          expect(template.errors[:campaign]).to include('change_not_allowed')
        end
      end

      describe "Can't be destroy when have technical_itineraries" do
        subject do
          @technical_itinerary = create(:technical_itinerary)
          @intervention_template = create(:intervention_template)
          TechnicalItineraryInterventionTemplate
            .create(technical_itinerary: @technical_itinerary,
                    intervention_template: @intervention_template,
                    position: 0)
        end

        it 'Intervention template is valid' do
          subject
          expect(@intervention_template).to be_valid
        end
      end

      describe 'Can be destroy without technical_itinerary' do
        subject { create(:intervention_template) }

        it 'Can be destroy' do
          intervention_template = subject
          expect { intervention_template.destroy }.to change { InterventionTemplate.count }.by(-1)
        end
      end
    end
  end
end
