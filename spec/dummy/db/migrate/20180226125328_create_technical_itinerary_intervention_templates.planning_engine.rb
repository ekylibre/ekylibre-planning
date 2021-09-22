# frozen_string_literal: true

# This migration comes from planning_engine (originally 20180116133217)
class CreateTechnicalItineraryInterventionTemplates < ActiveRecord::Migration
  def change
    unless table_exists?(:technical_itinerary_intervention_templates)
      create_table :technical_itinerary_intervention_templates do |t|
        t.references :technical_itinerary, index: { name: :template_itinerary_id }, foreign_key: true
        t.references :intervention_template, index: { name: :itinerary_template_id }, foreign_key: true
        t.integer :position
        t.integer :day_between_intervention
        t.integer :duration
        t.timestamps null: false
      end
    end
  end
end
