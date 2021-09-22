module Planning
  module InterventionTemplateLists
    extend ActiveSupport::Concern

    included do
      manage_restfully except: [:show]

      # unroll

      def self.list_conditions
        code = ''
        code = "#{search_conditions('intervention_template': %i[name])} ||= []\n"
        code << "if current_campaign\n"
        code << "  c[0] << \" AND #{InterventionTemplate.table_name}.campaign_id = ?\"\n"
        code << "  c << current_campaign.id\n"
        code << "end\n"

        # Procedure
        code << "if params[:procedure_name].present?\n"
        code << "  c[0] << ' AND #{InterventionTemplate.table_name}.procedure_name = ?'\n"
        code << "  c << params[:procedure_name]\n"
        code << "end\n"

        # Activity
        code << "if params[:activity_id].present?\n"
        code << "  c[0] << ' AND #{InterventionTemplate.table_name}.id IN (SELECT intervention_template_id FROM #{InterventionTemplateActivity.table_name} WHERE #{InterventionTemplateActivity.table_name}.activity_id IN (?))'\n"
        code << "  c << [params[:activity_id], nil]\n"
        # Add in the search the Planning::InterventionTemplate who don't have activity
        code << "  c[0] << ' OR #{InterventionTemplate.table_name}.id IN (SELECT #{InterventionTemplate.table_name}.id FROM #{InterventionTemplate.table_name} INNER JOIN #{InterventionTemplateActivity.table_name} ON #{InterventionTemplateActivity.table_name}.intervention_template_id = #{InterventionTemplate.table_name}.id WHERE #{InterventionTemplateActivity.table_name}.activity_id IS NULL)'\n"
        code << "end\n"
        code << "c\n"
        code.c
      end

      list(conditions: list_conditions, order: { created_at: :desc }) do |t|
        t.action :edit
        t.action :destroy
        t.column :name, url: true
        t.column :list_of_activities
        t.column :human_workflow, label: :workflow
        t.column :preparation_time
        t.column :total_cost
        t.column :created_at
        t.column :updated_at
        t.column :active
        t.column :description
      end

      list(
        :technical_itineraries,
        model: :technical_itineraries,
        conditions: {
          id: "TechnicalItinerary
        .joins(:itinerary_templates)
        .where(technical_itinerary_intervention_templates: { intervention_template_id: params[:id]})
        .pluck(:id)".c
        }
      ) do |t|
        t.column :name, url: true
        t.column :created_at
        t.column :human_duration, label: :duration
        t.column :activity
        t.column :total_cost
      end
    end
  end
end
