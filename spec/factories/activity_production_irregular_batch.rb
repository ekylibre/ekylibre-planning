FactoryBot.define do
  factory :activity_production_irregular_batch, class: 'ActivityProduction::IrregularBatch' do
    estimated_sowing_date { Time.now + 30.days }
    area { rand(1..200) }
    activity_production_batch
  end
end
