require 'faker'
FactoryBot.define do
  factory :product_nature_variant do
    name Faker::Name.name
  end
end
