module Planning
  class TechnicalItinerariesController < Planning::ApplicationController
    include ApplicationHelper
    manage_restfully except: [:show], model_name: TechnicalItinerary.to_s

    unroll model: 'technical_itinerary'

    def self.list_conditions
      code = ''
      code = "#{search_conditions('technical_itinerary': %i[name])} ||= []\n"

      code << "if current_campaign\n"
      code << "  c[0] << \" AND #{TechnicalItinerary.table_name}.campaign_id = ?\"\n"
      code << "  c << current_campaign.id\n"
      code << "end\n"

      # Activity
      code << "if params[:activity_id].present?\n"
      code << "  c[0] << ' AND #{TechnicalItinerary.table_name}.activity_id = ?'\n"
      code << "  c << params[:activity_id]\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, 
         model: TechnicalItinerary,
         joins: <<-SQL,
           LEFT JOIN "technical_itinerary_intervention_templates" ON "technical_itinerary_intervention_templates"."technical_itinerary_id" = "technical_itineraries"."id"
           LEFT JOIN "intervention_templates" ON "intervention_templates"."id" = "technical_itinerary_intervention_templates"."intervention_template_id"
           LEFT JOIN "intervention_template_product_parameters" ON "intervention_template_product_parameters"."intervention_template_id" = "intervention_templates"."id"
           LEFT JOIN "product_nature_variants" ON "product_nature_variants"."id" = "intervention_template_product_parameters"."product_nature_variant_id"
         SQL
         distinct: true,
         order: { created_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      # t.column :activity, url: true
      t.column :human_duration, label: :duration
      # t.column :total_cost
      t.column :created_at
      t.column :updated_at
      t.column :description
      t.column :plant_density
    end

    list(
      :intervention_templates,
      model: TechnicalItineraryInterventionTemplate,
      order: { position: :asc },
      conditions: { technical_itinerary_id: 'params[:id]'.c }
    ) do |t|
      t.column :position
      t.column :human_day_between_intervention, label: :delay, hidden: true, class: 'center'
      t.column :intervention_template, label: :name, url: true
      t.column :day_since_start, label: :day_since_start, class: 'center'
      t.column :human_day_compare_to_planting, label: :day_compare_to_planting, class: 'center'
      t.column :human_workflow, label: :workflow, through: :intervention_template
      t.column :inputs_or_outputs, label: :inputs_or_outputs, hidden: true
    end

    list(
      :activity_productions,
      model: ActivityProduction,
      conditions: { technical_itinerary_id: 'params[:id]'.c }
    ) do |t|
      t.column :name, url: { controller: 'backend/activity_productions', id: 'RECORD.id'.c }
      t.column :human_support_shape_area, label: :net_surface_area
      # t.column :planning_working_zone_area, label: :working_area
    end

    def new
      target_campaign = Campaign.find_by(id: params[:campaign_id])
      originator = TechnicalItinerary.find_by(id: params[:originator_id])

      if target_campaign && originator
        @valid_duplicate_intervention_templates = originator.intervention_templates.select do |i|
          i.linked_intervention_template&.campaign == target_campaign
        end.uniq

        @unvalid_duplicate_intervention_templates = originator.intervention_templates.select do |i|
          i.linked_intervention_template && i.linked_intervention_template.campaign != target_campaign
        end.uniq

        @unduplicate_intervention_templates = originator.intervention_templates.select do |i|
          i.linked_intervention_template.blank?
        end.uniq
      end

      if params[:modal_computed] || (@valid_duplicate_intervention_templates.present? && @unduplicate_intervention_templates.blank?)
        intervention_templates = InterventionTemplate.where(id: params[:to_duplicate_collection])
        intervention_templates.duplicate_collection(target_campaign)

        intervention_template_ids = InterventionTemplate
                                    .select(:id)
                                    .joins(:technical_itinerary_intervention_templates)
                                    .where('technical_itinerary_intervention_templates.technical_itinerary_id = ?', originator.id)
                                    .distinct(:id)

        duplicated_intervention_templates = InterventionTemplate.where(originator_id: intervention_template_ids,
                                                                       campaign: target_campaign)

        @technical_itinerary = originator.dup
        @technical_itinerary.campaign = target_campaign
        @technical_itinerary.originator = originator
        itinerary_templates = TechnicalItineraryInterventionTemplate
                              .where(
                                technical_itinerary: originator,
                                intervention_template: duplicated_intervention_templates.pluck(:originator_id)
                              )

        itinerary_templates.each do |itinerary_template|
          duplicate_itinerary_template = itinerary_template.dup
          duplicate_itinerary_template.intervention_template = itinerary_template.intervention_template.linked_intervention_template
          duplicate_itinerary_template.technical_itinerary_id = nil
          @technical_itinerary.itinerary_templates << duplicate_itinerary_template
        end
      else
        @technical_itinerary = if target_campaign && originator
                                 TechnicalItinerary.new(campaign: target_campaign, originator: originator)
                               else
                                 TechnicalItinerary.new(campaign: current_campaign)
                               end
      end
      params[:namespace] = :planning
    end

    def create
      technical_itinerary = TechnicalItinerary.new(permitted_params)
      respond_to do |format|
        if technical_itinerary.save
          format.json { render json: technical_itinerary, status: :created }
        else
          format.json do
            render json: technical_itinerary.errors.full_messages, status: :unprocessable_technical_itinerary
          end
        end
      end
    end

    def index
      # 'TechnicalItineraryPrinter' printer are localize in eky/app/services/printers
      # and 'technical_itinerary_sheet' template are localize in eky/config/locales/fra/printers
      # params [technical_itinerary_ids] Array of ids of TechnicalItinerary
      # params [campaign] Campaign
      @technical_itinerary_document = DocumentTemplate.find_by(nature: :technical_itinerary_sheet)
      @technical_itineraries_of_campaign = TechnicalItinerary.of_campaign(current_campaign)
      respond_to do |format|
        format.html
        format.pdf {
          return unless @technical_itinerary_document

          PrinterJob.perform_later('Printers::TechnicalItineraryPrinter', template: @technical_itinerary_document, technical_itinerary_ids: @technical_itineraries_of_campaign.pluck(:id), campaign: current_campaign, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to action: :index
        }
      end
    end

    def show
      find_technical_itinerary
      @technical_itinerary_document = DocumentTemplate.find_by(nature: :technical_itinerary_sheet)
      if request.format.html?
        t3e(name: @technical_itinerary.name, campaign_name: @technical_itinerary.campaign.name)
      elsif request.format.pdf?
        return unless @technical_itinerary_document

        PrinterJob.perform_later('Printers::TechnicalItineraryPrinter', template: @technical_itinerary_document, technical_itinerary_ids: [@technical_itinerary.id], campaign: current_campaign, perform_as: current_user)
        notify_success(:document_in_preparation)
        redirect_to action: :show
      end
    end

    def edit
      find_technical_itinerary
      t3e(technical_itinerary: @technical_itinerary.name, campaign_name: @technical_itinerary.campaign.name)

      params[:namespace] = :planning

      render(locals: { cancel_url: :back })
    end

    def update
      find_technical_itinerary
      respond_to do |format|
        if @technical_itinerary.update(permitted_params)
          format.json { render json: @technical_itinerary, status: :ok }
        else
          format.json do
            render json: @technical_itinerary.errors.full_messages, status: :unprocessable_technical_itinerary
          end
        end
      end
    end

    def destroy
      find_technical_itinerary
      @technical_itinerary.destroy

      redirect_to action: :index
    end

    def duplicate
      return unless @technical_itinerary = TechnicalItinerary.find_by(id: params[:id])

      respond_to do |format|
        format.js
      end
    end

    def duplicate_intervention
      response = params[:response]
      templates = params[:templates]
      duplicate_template = response[:template]
      hash = SecureRandom.uuid

      # remove hold duplicate template and update next template day_between_intervention
      if duplicate_template[:reference_hash].present?
        templates_to_remove = templates.select { |t| t[:parent_hash] == duplicate_template[:reference_hash] }
        templates_to_remove.each do |template|
          next_template = templates.select do |t|
                            t[:_destroy].nil? && t[:position] > template[:position]
                          end.min_by { |t| t[:position] }
          if next_template.present?
            next_template[:day_between_intervention] =
              next_template[:day_between_intervention].to_i + template[:day_between_intervention].to_i
          end
          if template[:id].present?
            template._destroy = '1'
          else
            templates.delete(template)
          end
        end
      end

      valid_templates = templates
                        .select { |t| t[:_destroy].nil? && t[:position] > duplicate_template[:position] }
                        .sort_by { |t| t[:position] }

      number_of_repetition = response[:repeteTimes].to_i
      repete_interval = response[:repeteInterval].to_i
      last_aid = templates.present? ? templates.max_by { |t| t[:aid] }[:aid] : 0
      origin_position = duplicate_template[:position]
      diff = repete_interval
      number_of_template_inserted = 0
      position = origin_position + 1
      last_is_negative = false

      valid_templates.each_with_index do |template, _index|
        if number_of_template_inserted < number_of_repetition
          if template[:day_between_intervention].to_i > diff.to_i
            while template[:day_between_intervention].to_i >= diff.to_i
              last_aid += 1
              new_template = set_new_template(duplicate_template, position, last_aid, hash)
              new_template[:day_between_intervention] = diff
              templates << new_template
              template[:position] = position + 1
              number_of_template_inserted += 1
              position += 1
              last_is_negative = false
              if diff + repete_interval > template[:day_between_intervention].to_i || number_of_template_inserted == number_of_repetition
                break
              end

              template[:day_between_intervention] = template[:day_between_intervention].to_i - diff
              diff = repete_interval

            end

            original_template_diff = template[:day_between_intervention].to_i
            template[:day_between_intervention] = original_template_diff - diff
            new_template_diff = new_template[:day_between_intervention].to_i - repete_interval.to_i

            diff = if new_template_diff.positive?
                     new_template_diff
                   else
                     repete_interval.to_i - template[:day_between_intervention].to_i
                   end

          else
            diff -= template[:day_between_intervention].to_i
            position += 1
            template[:position] = position
            position += 1
            last_is_negative = true
          end
        else
          position += 1
          template[:position] = position
        end
      end

      if number_of_template_inserted < number_of_repetition
        (number_of_repetition - number_of_template_inserted).times do
          last_aid += 1
          position += 1
          new_template = set_new_template(duplicate_template, position, last_aid, hash)
          new_template[:day_between_intervention] = diff
          templates << new_template
          diff = repete_interval
        end
      end

      t = templates.detect { |f| f[:position] == duplicate_template[:position] }
      t[:reference_hash] = hash

      respond_to do |format|
        format.json { render json: templates }
      end
    end

    private

    def set_new_template(duplicate_template, position, last_aid, hash)
      new_template = duplicate_template.clone
      new_template[:id] = nil
      new_template[:position] = position
      new_template[:aid] = last_aid
      new_template[:is_duplicate] = true
      new_template[:parent_hash] = hash
      new_template[:reference_hash] = nil
      new_template
    end

    def permitted_params
      params.require(:technical_itinerary).permit(
        :name,
        :activity_id,
        :description,
        :plant_density,
        :campaign_id,
        :creator_id,
        :updater_id,
        :originator_id,
        itinerary_templates_attributes: %i[id
                                           _destroy
                                           position
                                           day_between_intervention
                                           intervention_template_id
                                           duration
                                           dont_divide_duration
                                           parent_hash
                                           reference_hash]
      )
    end

    def find_technical_itinerary
      @technical_itinerary = TechnicalItinerary.find(params[:id])
    end
  end
end
