# frozen_string_literal: true

require 'faker'
FactoryBot.define do
  factory :intervention_template do
    name Faker::Name.name
    workflow { rand(0..30) }
    campaign
    procedure_name Faker::Name.name
  end
end
