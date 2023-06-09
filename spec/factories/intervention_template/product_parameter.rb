# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  procedure_type = %w[driver spreader trailed_equipment tractor stubble_cultivator plow
                      soil_loosener harrow plant sower].sample
  factory :product_parameter, class: InterventionTemplate::ProductParameter do
    quantity { rand(1..100) }
    unit do
      %w[unit
         ton_per_hectare
         thousand_per_hectare
         kilogram_per_hectare
         liter_per_hectare
         square_meter
         ton
         quintal_per_hectare].sample
    end
    product_nature
    product_nature_variant
    procedure { { type: procedure_type } }
  end

  def sample_type
    %w[driver spreader trailed_equipment].sample
  end
end
