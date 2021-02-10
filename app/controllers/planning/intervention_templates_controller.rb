module Planning
  class InterventionTemplatesController < Planning::ApplicationController
    manage_restfully except: [:show], model_name: InterventionTemplate.to_s


    def self.list_conditions
      code = ''
      code = search_conditions("intervention_template": %i[name]) + " ||= []\n"

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
      code << "  c[0] << ' AND (#{InterventionTemplate.table_name}.id IN (SELECT intervention_template_id FROM #{InterventionTemplateActivity.table_name} WHERE #{InterventionTemplateActivity.table_name}.activity_id IN (?))'\n"
      code << "  c << [params[:activity_id], nil]\n"

      # Add in the search the Planning::InterventionTemplate who don't have activity
      code << "  c[0] << ' OR #{InterventionTemplate.table_name}.id IN (SELECT #{InterventionTemplate.table_name}.id FROM #{InterventionTemplate.table_name} INNER JOIN #{InterventionTemplateActivity.table_name} ON #{InterventionTemplateActivity.table_name}.intervention_template_id = #{InterventionTemplate.table_name}.id WHERE #{InterventionTemplateActivity.table_name}.activity_id IS NULL))'\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, model: InterventionTemplate, order: { created_at: :desc }) do |t|
      t.action :duplication_list, on: :many, method: :get
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
      model: TechnicalItinerary,
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

    def select_type
      family_names = ['administering', 'plant_farming']
      @family_categories = []
      family_names.each do |name|
        element = {}
        element[:family] = Onoma::ActivityFamily.find(name)
        element[:categories] = Onoma::ProcedureCategory.select { |c| c.activity_family.include?(element[:family].name.to_sym) }
        @family_categories << element
      end
    end

    def new
      # Set options from params for the new
      options = {}
      %i[procedure_name].each { |p| options[p] = params[p] }
      options[:campaign] = current_campaign
      @intervention_template = InterventionTemplate.new(options)
      @intervention_template.creator ||= current_user
      @intervention_template.updater = current_user
      procedure
      # Translate the name of the procedure for the title
      t3e(procedure_name: @procedure.human_name)
      @no_menu = true

      params[:namespace] = :planning

      render(locals: { with_continue: true })
    end

    def create
      @intervention_template = InterventionTemplate.new(permitted_params)

      respond_to do |format|
        if @intervention_template.save
          format.json { render json: @intervention_template, status: :created }
        else
          format.json { render json: @intervention_template.errors.full_messages, status: :unprocessable_intervention_template }
        end
      end
    end

    def update
      find_intervention_template

      respond_to do |format|
        if @intervention_template.update(permitted_params)
          format.json { render json: @intervention_template, status: :ok }
        else
          format.json { render json: @intervention_template.errors.full_messages, status: :unprocessable_intervention_template }
        end
      end
    end

    def show
      find_intervention_template
      t3e(name: @intervention_template.name, campaign_name: @intervention_template.campaign.name)
    end

    def edit
      find_intervention_template
      @intervention_template.creator ||= current_user
      @intervention_template.updater = current_user
      procedure
      t3e(procedure_name: @procedure.human_name, campaign_name: @intervention_template.campaign.name)
      params[:namespace] = :planning
    end

    def destroy
      find_intervention_template
      @intervention_template.destroy

      redirect_to action: :index
    end

    def duplication_list
      intervention_templates = InterventionTemplate.where(id: params[:id].split(','))
      @unvalid_intervention_templates = intervention_templates.select { |i| i.linked_intervention_template.present? }
      @valid_intervention_templates = (intervention_templates.pluck(:id) - @unvalid_intervention_templates.map(&:id)).join(',')
      respond_to do |format|
        format.js {}
      end
    end

    def duplicate_intervention_templates
      intervention_templates = InterventionTemplate.where(id: params[:id].split(','))
      campaign = Campaign.find(params[:campaign])

      intervention_templates.duplicate_collection(campaign)
      notify_success(:intervention_templates_was_duplicated.tl)
      redirect_to action: :index
    end

    def duplicate
      return unless intervention_template = InterventionTemplate.find_by(id: params[:id])
      campaign = intervention_template.campaign.following
      @intervention_template = intervention_template.instanciate_duplicate(campaign)
      procedure
      t3e(procedure_name: @procedure.human_name)
      params[:namespace] = :planning
      render :new
    end

    def templates_of_activity
      activity_id, campaign_id = nil, nil

      if params[:options].present?
        activity_id = params[:options][:activity_id]
        campaign_id = params[:options][:campaign_id]
      end

      q = "%#{params[:q]}%".downcase
      templates = if activity_id
        InterventionTemplate.joins(:association_activities)
                            .where(intervention_template_activities: { activity_id: [nil, activity_id] })
                            .where("lower(intervention_templates.name) LIKE :name",
                            activity_id: [nil, activity_id],
                            name: q)
                            .where(campaign_id: campaign_id)
      else
        InterventionTemplate.joins(:association_activities)
                            .where(intervention_template_activities: { activity_id: nil })
                            .where("lower(intervention_templates.name) LIKE :name", name: q)
                            .where(campaign_id: campaign_id)
      end

      templates.each do |t|
        t.is_planting = t.planting?
        t.is_harvesting = t.harvesting?
      end

      respond_to do |format|
        format.json { render json: templates }
      end
    end

    def interventions_have_activities
      intervention_template_ids = []

      if params[:templates].present?
        params[:templates].each do |t|
          intervention_template_ids << t[1][:intervention_template_id] if t[1][:_destroy].blank?
        end

        templates = InterventionTemplate.joins(:association_activities)
        .where("intervention_templates.id IN (?)
        AND intervention_template_activities.activity_id IS NOT null",
        intervention_template_ids)

        respond_to do |format|
          format.json { render json: templates.any? }
        end
      else
        respond_to do |format|
          format.json { render json: false }
        end
      end
    end

    private

    def find_intervention_template
      @intervention_template = InterventionTemplate.find(params[:id])
    end

    def procedure
      @procedure = @intervention_template.procedure
    end

    def permitted_params
      params.require(:intervention_template).permit(:name,
                                                    :active,
                                                    :description,
                                                    :procedure_name,
                                                    :workflow,
                                                    :preparation_time_hours,
                                                    :preparation_time_minutes,
                                                    :campaign_id,
                                                    :creator_id,
                                                    :updater_id,
                                                    :originator_id,
                                                    product_parameters_attributes: [:id,
                                                                                    :product_nature_id,
                                                                                    :product_nature_variant_id,
                                                                                    :quantity,
                                                                                    :unit,
                                                                                    :_destroy,
                                                                                    procedure: [:name, :type],
                                                                                  ],
                                                                                  association_activities_attributes: [:id,
                                                                                        :activity_id,
                                                                                        :_destroy])
    end
  end
end
