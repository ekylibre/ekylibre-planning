require 'faker'
FactoryBot.define do
  factory :product_nature do
    name Faker::Name.name
  end
end
