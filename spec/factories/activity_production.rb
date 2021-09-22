# frozen_string_literal: true

require 'faker'
FactoryBot.define do
  factory :activity_production, class: 'ActivityProduction' do
    name Faker::Name.name
    started_on Time.now + 10.days
    stopped_on Time.now + 1.year
  end

  factory :activity_production_with_template, class: 'ActivityProduction' do
    name Faker::Name.name
    started_on Time.now + 10.days
    stopped_on Time.now + 1.year
    technical_itinerary
  end
end
