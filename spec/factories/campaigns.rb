# frozen_string_literal: true

require 'faker'
FactoryBot.define do
  factory :campaign do
    name Faker::Name.name
  end
end
