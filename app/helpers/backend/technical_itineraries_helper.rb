# frozen_string_literal: true

module Backend
  module TechnicalItinerariesHelper
    def itinerary_templates_list
      itinerary_templates = @technical_itinerary.itinerary_templates.includes(:intervention_template)
      itinerary_templates = @technical_itinerary.itinerary_templates if itinerary_templates.empty?

      itinerary_templates.each do |i|
        i.intervention_template_name = i.intervention_template&.name
        i.is_planting                = i.intervention_template&.planting?
        i.is_harvesting              = i.intervention_template&.harvesting?
        i.procedure_name             = i.intervention_template&.procedure_name
      end.to_json
    end
  end
end
