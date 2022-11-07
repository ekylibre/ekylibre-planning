module Planning
  class SchedulingsController < Planning::ApplicationController
    before_action :set_intervention_proposal, only: [:update_estimated_date]

    def index
      today = Time.now

      @land_parcels = LandParcel.availables(at: today)
      @workers = Worker.availables(at: today)
      @equipments = Equipment.availables(at: today)
      @activities = Activity.all
      @procedures = Intervention.used_procedures

      @selected_land_parcel = select_preference('land_parcel_id')
      @selected_worker_id = select_preference('worker_id')
      @selected_equipment_id = select_preference('equipment_id')
      @selected_activity_id = select_preference('activity_id')
      @selected_procedure_name = select_preference('procedure_name')
    end

    def change_week_preference
      @day = params[:date]
      save_preferences
      render json: { save: true }
    end

    def update_estimated_date
      if @intervention_proposal.nil? || !permitted_params.key?(:day)
        return render json: { error: 'Intervention proposal id not valid' }
      end

      new_date = Date.parse(permitted_params[:day])
      @intervention_proposal.update_column(:estimated_date, new_date)

      render json: @intervention_proposal
    end

    def update_intervention_dates
      interactor = ::Interventions::UpdateInterventionDatesInteractor
                   .call(permitted_params)

      render json: interactor.intervention if interactor.success?
      render json: interactor.error if interactor.fail?
    end

    def weekly_daily_charges
      init_day

      beginning_of_week = @day
                          .beginning_of_week
                          .beginning_of_day

      end_of_week = @day
                    .end_of_week
                    .end_of_day

      @intervention_proposals = InterventionProposal
                                .between_date(beginning_of_week, end_of_week)
                                .of_land_parcel(params[:land_parcel_id])
                                .of_product_types([params[:worker_id], params[:equipment_id]])
                                .of_activity(params[:activity_id])
                                .of_procedure(params[:procedure_name])
                                .of_product_parameter_or_nil(params[:worker_id])
                                .of_product_parameter_or_nil(params[:equipment_id])

      @planned_interventions = ::Interventions::PlannedInterventionsNotRealizedQuery
                               .call(::Intervention, @day, permitted_params)

      @week_days = (@day.beginning_of_week..@day.end_of_week).map.with_index do |day, index|
        { 
          day: I18n.l(day, format: '%A %d %B'),
          formatted_day: day.to_time.strftime('%Y/%m/%d'),
          index: index
        }
      end

      save_preferences

      respond_to do |format|
        format.json
      end
    end

    def intervention_chronologies
      @production = if params[:activity_production_id].present?
                      ActivityProduction.find(params[:activity_production_id]).support
                    else
                      LandParcel.includes(:activity_production).find params[:land_parcel_id]
                    end
      @period_started_on = @production.activity_production.started_on.beginning_of_month
      @period_stopped_on = @production.activity_production.stopped_on.end_of_month
      @duration = (@period_stopped_on - @period_started_on).to_f
      @grades = []
      on = @period_started_on
      while on < @period_stopped_on + 1.month
        @grades << on
        on += 1.month
      end

      render partial: 'planning/schedulings/intervention_chronologies'
    end

    def new_intervention
      intervention_proposal = InterventionProposal.find(params[:intervention_proposal_id])
      activity = intervention_proposal.technical_itinerary_intervention_template.technical_itinerary.activity
      render partial: 'planning/schedulings/create_intervention',
             locals: { intervention_proposal: intervention_proposal, activity: activity }
    end

    def update_proposal
      intervention_proposal = InterventionProposal.find(params[:proposal_id])
      intervention_template = intervention_proposal
                              .technical_itinerary_intervention_template
                              .intervention_template
      intervention_proposal.target = params[:target]
      %i[doers tools inputs].each do |type|
        next unless params[type].present?

        params[type].each_with_index do |p, index|
          parameter = intervention_proposal.parameters.of_product_type(type.to_s.singularize).order(:id)[index]
          if parameter.present?
            if p.instance_of?(Array)
              parameter.product_id = p.last[:product_id]
              parameter.quantity = p.last[:quantity]
              parameter.unit = p.last[:unit]
              parameter.intervention_template_product_parameter_id = p.last[:parameter_id]
              parameter.save
            else
              parameter.update(product_id: p)
            end
          elsif p.instance_of?(Array)
            intervention_proposal
              .parameters
              .build(product_type: type.to_s.singularize,
                     product_id: p.last[:product_id],
                     quantity: p.last[:quantity],
                     unit: p.last[:unit],
                     intervention_template_product_parameter_id: p.last[:parameter_id])
          else
            intervention_proposal.parameters.build(product_type: type.to_s.singularize, product_id: p)
          end
        end
      end

      %i[outputs].each do |type|
        next unless params[type].present?

        params[type].each_with_index do |p, index|
          parameter = intervention_proposal.parameters.of_product_type(type.to_s.singularize).order(:id)[index]
          if parameter.present?
            if p.instance_of?(Array)
              parameter.product_nature_variant_id = p.last[:variant_id]
              parameter.quantity = p.last[:quantity]
              parameter.unit = p.last[:unit]
              parameter.intervention_template_product_parameter_id = p.last[:parameter_id]
              parameter.save
            else
              parameter.update(product_id: p)
            end
          elsif p.instance_of?(Array)
            intervention_proposal
              .parameters
              .build(product_type: type.to_s.singularize,
                     product_nature_variant_id: p.last[:variant_id],
                     quantity: p.last[:quantity],
                     unit: p.last[:unit],
                     intervention_template_product_parameter_id: p.last[:parameter_id])
          elsif p.present?
            intervention_proposal.parameters.build(product_type: type.to_s.singularize, product_id: p)
          end
        end
      end

      parameters = intervention_proposal.parameters.of_product_type(:parcel)
      if parameters.present?
        parameters.last.update(product_id: params[:parcel])
      else
        intervention_proposal.parameters.build(product_type: :parcel, product_id: params[:parcel])
      end

      intervention_proposal.save

      respond_to do |format|
        format.json { render json: { response: true } }
      end
    end

    def new_detailed_intervention
      interactor = ::Interventions::BuildInterventionWithProposalInteractor
                   .call(permitted_params)

      @intervention = interactor.intervention
      if @intervention.missing_parameters.any?
        @intervention.missing_parameters.each do |param|
          @intervention.decorate.build_invalid_parameter(param)
        end
      end
      @intervention.valid? if params[:check_validity] == 'true'
    end

    def create_intervention
      interactor = ::Interventions::BuildInterventionWithProposalInteractor
                   .call(permitted_params)

      if interactor.fail?
        render json: { save: false, errors: interactor.error }
      else
        @intervention = interactor.intervention

        return render json: { save: false, errors: 'Missing parameters' } if @intervention.missing_parameters.any?

        if @intervention.save
          notify_success(:record_x_planned,
                         record: @intervention.model_name.human,
                         name: @intervention.number)

          render json: { save: true }
        else
          render json: { save: false, errors: @intervention.errors }
        end
      end
    end

    def update_modal_time
      proposal = InterventionProposal.find(params[:proposal_id])

      case params[:target]
      when 'land_parcel'
        target_parcel = LandParcel.find(params[:value_id]) if params[:value_id].present?
      when 'plant'
        target_parcel = Plant.find(params[:value_id]) if params[:value_id].present?
      end

      time = proposal.human_estimated_working_time(target_parcel) if target_parcel.present?

      respond_to do |format|
        format.json { render json: { time: time || '00 : 00' } }
      end
    end

    private

    def init_day
      new_date = Date.parse(params[:day]) if params[:day].present?

      if params[:week].present?
        @day = if params[:week].to_sym == :next
                 new_date.next_week
               else
                 new_date.prev_week
               end

        return
      end

      @day = new_date if new_date.present?

      day_preference = select_preference('day')
      @day ||= Date.parse(day_preference) if day_preference.present?
      @day ||= Time.now.to_date if @day.blank?
    end

    def save_preferences
      params_to_check = params.except(:isTrusted, :controller, :action, :day)

      params_to_check.each do |key, value|
        preference_name = "schedulings_calendar.#{key}"

        ::Preference.set!(preference_name, value)
      end

      ::Preference.set!('schedulings_calendar.day', @day.to_s)
    end

    def select_preference(name)
      preference = Preference.find_by_name("schedulings_calendar.#{name}")
      preference&.value
    end

    def set_intervention_proposal
      return unless permitted_params.key?(:id)

      @intervention_proposal = InterventionProposal.find(permitted_params[:id])
    end

    def permitted_params
      params.permit(:id,
                    :day,
                    :proposal_id,
                    :land_parcel_id,
                    :worker_id,
                    :equipment_id,
                    :activity_id,
                    :procedure_name)
    end
  end
end
