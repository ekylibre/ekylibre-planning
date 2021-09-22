# frozen_string_literal: true

require 'faker'
FactoryBot.define do
  factory :daily_charge do
    reference_date { Time.now + 5.days }
    product_type 'tractor'
    quantity 2
    area 6
    product_parameter
    activity_production
  end
end
