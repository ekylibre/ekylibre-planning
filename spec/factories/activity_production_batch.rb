# frozen_string_literal: true

FactoryBot.define do
  factory :activity_production_batch, class: ActivityProduction::Batch do
    number { rand(1..30) }
    day_interval { rand(1..60) }
    irregular_batch false
    activity_production
  end
end
