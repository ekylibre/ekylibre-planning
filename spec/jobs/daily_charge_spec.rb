# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DailyChargeJob, type: :job do
  # subject do
  #   activity_production = create(:activity_production_with_template)
  #   technical_itinerary = activity_production.technical_itinerary
  #   intervention_template = create(:intervention_template)
  #   create(:product_parameter, intervention_template: intervention_template)
  #   TechnicalItineraryInterventionTemplate
  #   .create(technical_itinerary: technical_itinerary,
  #   intervention_template: intervention_template,
  #   position: 0)
  #   activity_production
  # end
  #
  # describe 'In classic mode (no batch)' do
  #   it 'is valid in classic mode' do
  #     expect { DailyChargeJob.perform_now(subject) }.to change { DailyCharge.count }.by(1)
  #   end
  #
  #   it 'Update the precedent DailyCharge' do
  #     activity_production = subject
  #     DailyChargeJob.perform_now(activity_production)
  #     daily_charge_id = DailyCharge.last.id
  #     DailyChargeJob.perform_now(activity_production)
  #     expect(DailyCharge.last.id).to eq(daily_charge_id + 1)
  #   end
  # end
  #
  # describe 'With classic batch' do
  #   subject do
  #     activity_production = create(:activity_production_with_template, batch_planting: true)
  #     technical_itinerary = activity_production.technical_itinerary
  #     intervention_template = create(:intervention_template)
  #     create(:product_parameter, intervention_template: intervention_template)
  #     TechnicalItineraryInterventionTemplate
  #     .create(technical_itinerary: technical_itinerary,
  #     intervention_template: intervention_template,
  #     position: 0)
  #     create(:activity_production_batch, activity_production: activity_production, number: 1)
  #     activity_production
  #   end
  #
  #   it 'With one activity production batch' do
  #     expect { DailyChargeJob.perform_now(subject) }.to change { DailyCharge.count }.by(1)
  #   end
  #
  #   it 'with many activity production batch' do
  #     activity_production = subject
  #     create(:activity_production_batch, activity_production: activity_production, number: 2)
  #     expect { DailyChargeJob.perform_now(activity_production) }.to change { DailyCharge.count }.by(2)
  #   end
  # end
  #
  # describe 'With irregular batch' do
  #   subject do
  #     activity_production = create(:activity_production_with_template, batch_planting: true)
  #     technical_itinerary = activity_production.technical_itinerary
  #     intervention_template = create(:intervention_template)
  #     create(:product_parameter, intervention_template: intervention_template)
  #     TechnicalItineraryInterventionTemplate
  #     .create(technical_itinerary: technical_itinerary,
  #     intervention_template: intervention_template,
  #     position: 0)
  #     @activity_production_batch = create(:activity_production_batch, activity_production: activity_production, irregular_batch: true)
  #     create(:activity_production_irregular_batch, activity_production_batch: @activity_production_batch)
  #     activity_production
  #   end
  #
  #   it 'With one irregular batch' do
  #     expect { DailyChargeJob.perform_now(subject) }.to change { DailyCharge.count }.by(1)
  #   end
  #
  #   it 'With manny irregular batches' do
  #     activity_production = subject
  #     create(:activity_production_irregular_batch, activity_production_batch: @activity_production_batch)
  #     expect { DailyChargeJob.perform_now(activity_production) }.to change { DailyCharge.count }.by(2)
  #   end
  # end
end

# expect { intervention_template.destroy }.to change { InterventionTemplate.count }.by(-1)
