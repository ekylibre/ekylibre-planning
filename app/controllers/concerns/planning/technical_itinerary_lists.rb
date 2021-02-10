module Planning::TechnicalItineraryLists
  extend ActiveSupport::Concern

  included do
    manage_restfully except: [:show]
    unroll

    def self.list_conditions
      code = ''
      code = search_conditions(technical_itineraries: %i[name]) + " ||= []\n"
      code << "if current_campaign\n"
      code << "  c[0] << \" AND #{TechnicalItinerary.table_name}.campaign_id = ?\"\n"
      code << "  c << current_campaign.id\n"
      code << "end\n"

      #Activity
      code << "if params[:activity_id].present?\n"
      code << "  c[0] << ' AND #{TechnicalItinerary.table_name}.activity_id = ?'\n"
      code << "  c << params[:activity_id]\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, order: { created_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :activity, url: true
      t.column :human_duration, label: :duration
      t.column :total_cost
      t.column :created_at
      t.column :updated_at
      t.column :description
    end

    list(
      :intervention_templates,
      model: :technical_itinerary_intervention_templates,
      order: { position: :asc },
      conditions: { technical_itinerary_id: 'params[:id]'.c }
    ) do |t|
      t.column :human_day_between_intervention, label: :delay
      t.column :intervention_template, label: :name, url: true
      t.column :human_day_compare_to_planting, label: :day_compare_to_planting
      t.column :human_workflow, label: :workflow, through: :intervention_template
    end

    list(
      :activity_productions,
      model: :activity_productions,
      conditions: { technical_itinerary_id: 'params[:id]'.c }
    ) do |t|
      t.column :name, url: true
      t.column :human_support_shape_area, label: :net_surface_area
      t.column :planning_working_zone_area, label: :working_area
    end
  end
end
