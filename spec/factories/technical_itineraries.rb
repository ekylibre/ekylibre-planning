require 'faker'
FactoryBot.define do
  factory :technical_itinerary do
    name Faker::Name.name
    campaign
    activity
  end
end
