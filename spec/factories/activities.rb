require 'faker'

FactoryBot.define do
  factory :activity do
    name Faker::Name.name
  end
end
