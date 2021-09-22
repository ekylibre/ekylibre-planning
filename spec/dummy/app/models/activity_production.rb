# frozen_string_literal: true

class ActivityProduction < ActiveRecord::Base
  belongs_to :technical_itinerary, class_name: 'TechnicalItinerary'
  scope :with_technical_itinerary, -> { where.not(technical_itinerary: nil) }
  has_many :daily_charges, class_name: 'DailyCharge', dependent: :destroy
  has_one :batch, class_name: 'ActivityProduction::Batch', dependent: :destroy, inverse_of: :activity_production

  def net_surface_area
    rand(1..100)
  end
end
