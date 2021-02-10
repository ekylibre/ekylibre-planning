require 'rails_helper'

RSpec.describe Backend::LoadPlansController, type: :controller do
  render_views
  let(:json) { JSON.parse(response.body) }

  describe 'Get index' do
    it 'assigns @activity_productions' do
      activity_production = create(:activity_production_with_template)
      get :index, format: :json
      # expect(assigns(:activity_productions)).to eq([activity_production])
      expect(json['activity_productions'].collect{ |l| l['name'] }).to include(activity_production.name)
    end
  end

  describe 'Get period charges' do
    subject do
      activity_production = create(:activity_production_with_template, batch_planting: true)
      technical_itinerary = activity_production.technical_itinerary
      intervention_template = create(:intervention_template)
      create(:product_parameter, intervention_template: intervention_template)
      TechnicalItineraryInterventionTemplate
      .create(technical_itinerary: technical_itinerary,
      intervention_template: intervention_template,
      position: 0)
      create(:activity_production_batch, activity_production: activity_production, number: 2)
      DailyChargeJob.perform_now(activity_production)
    end

    describe 'without periods in params'do
      it 'Should render periods' do
        get :period_charges, format: :json
        expect(json['labels'].any?).to be true
      end
    end

    describe 'Dataset' do
      it 'Should have dataset' do
        get :period_charges, format: :json
        expect(json['datasets'].any?).to be true
      end

      it 'Should have two elements in dataset (tool and doer)' do
        get :period_charges, { period: {from: Time.now, to: Time.now + 2.months }, format: :json }
        expect(json['datasets'].count).to eq(2)
        expect(json['datasets'].first['label']).to eq('equipments')
        expect(json['datasets'].second['label']).to eq('workforce')
      end
    end

    describe 'With periods in params' do
      it 'Should render periods' do
        get :period_charges, { period: {from: Time.now, to: Time.now + 2.months }, format: :json }
        expect(json['labels'].any?).to be true
      end
    end
  end
end
