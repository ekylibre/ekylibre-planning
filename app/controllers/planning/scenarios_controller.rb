module Planning
  class ScenariosController < Planning::ApplicationController
    # before_action :set_planning_scenario, only: [:show, :edit, :update, :destroy]
    manage_restfully except: [:show], model_name: Scenario.to_s

    def self.list_conditions
      code = ''
      code = "#{search_conditions('scenario': %i[name])} ||= []\n"

      code << "if current_campaign\n"
      code << "  c[0] << \" AND #{Scenario.table_name}.campaign_id = ?\"\n"
      code << "  c << current_campaign.id\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, model: Scenario) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :human_rotation_area, label: :rotation_area
      t.column :created_at
      t.column :updated_at
      t.column :description
    end

    list(
      :rotations,
      model: ScenarioActivity::Plot,
      conditions: { id: 'ScenarioActivity::Plot
                    .joins(:scenario_activity)
                    .where(planning_scenario_activities: { planning_scenario_id: params[:id] })
                    .select(:id)'.c }
    ) do |t|
      t.column :activity_name, through: :scenario_activity, label: :activities,
                               url: { controller: 'backend/activities', id: 'RECORD.scenario_activity.activity_id'.c }
      t.column :parcel_name, label: :plot
      t.column :human_area, label: :human_area
      t.column :technical_itinerary, url: true
      t.column :batch_planting
    end

    # # GET /planning/scenarios/new
    def new
      @scenario = Scenario.new
      params[:namespace] = :planning
      render 'backend/base/new'
    end

    def create
      @scenario = Scenario.new(planning_scenario_params)
      if @scenario.save
        if params[:visualisation]
          redirect_to planning_scenario_chart_path(scenario_id: @scenario)
        else
          redirect_to planning_scenario_path(@scenario), notice: 'Scenario was successfully created.'
        end
      else
        params[:namespace] = :planning
        render 'backend/base/new'
      end
    end

    def edit
      find_scenario
      t3e(scenario_name: @scenario.name)
      params[:namespace] = :planning
      render(locals: { cancel_url: :back })
    end

    def update
      find_scenario
      t3e(scenario_name: @scenario.name)
      if @scenario.update(planning_scenario_params)
        if params[:visualisation]
          redirect_to planning_scenario_chart_path(scenario_id: @scenario)
        else
          redirect_to planning_scenario_path(@scenario), notice: 'Scenario was successfully created.'
        end
      else
        params[:namespace] = :planning
        render 'backend/base/edit'
      end
    end

    def show
      find_scenario
      if request.format.html?
        t3e(name: @scenario.name, campaign_name: @scenario.campaign.name)
      else
        ScenarioExportJob.perform_later(@scenario, request.format.symbol.to_s, current_user)
        notify_success(:document_in_preparation)
        redirect_to :back
      end
    end

    def destroy
      find_scenario
      @scenario.destroy
      redirect_to planning_scenarios_path
    end

    def chart
      find_scenario
      t3e(scenario_name: @scenario.name)
      if request.format.html?
        nil
      else
        ScenarioExportJob.perform_later(@scenario, request.format.symbol.to_s, current_user)
        notify_success(:document_in_preparation)
        redirect_to :back
      end
    end

    def period_charges
      find_scenario
      period_params
      @daily_charges = @scenario.generate_daily_charges
      if @week.present?
        @from = Date.parse(@week)
        @to = @from.end_of_week
        @daily_charges.select! { |d| d.reference_date.between?(@from, @to) }
        get_labels(false)
      else
        @from = get_year_start_week(@now)
        @to   = @now.end_of_year.end_of_week
        get_labels(true)
      end
      @daily_charges.select! { |d| d.activity_id == params['activity_id'].to_i } if params['activity_id'].present?
      respond_to do |format|
        format.json
      end
    end

    private

    def get_year_start_week(time)
      week_beginning = time.beginning_of_year.beginning_of_week
      if week_beginning.year < time.year
        week_beginning.next_week
      else
        week_beginning
      end
    end

    def period_params
      @now = params[:year].present? ? "01/01/#{params[:year]}".to_date : Time.now
      year = @now.year
      @week = params[:week]&.insert(-1, "/#{year}")
      @day = params[:day]&.insert(-1, "/#{year}")
    end

    def get_labels(weekly_period)
      @labels = []
      from = @from
      while from <= @to
        @labels << from
        from = if weekly_period
                 from.next_week
               else
                 from + 1.day
               end
      end
      @labels
    end

    def get_year_start_week(time)
      week_beginning = time.beginning_of_year.beginning_of_week
      if week_beginning.year < time.year
        week_beginning.next_week
      else
        week_beginning
      end
    end

    #   # Only allow a trusted parameter "white list" through.
    def planning_scenario_params
      params
        .require(:scenario)
        .permit(:campaign_id,
                :name,
                :description,
                scenario_activities_attributes: [
                  :id,
                  :activity_id,
                  :_destroy,
                  { plots_attributes: [
                    :id,
                    :technical_itinerary_id,
                    :area,
                    :planned_at,
                    :batch_planting,
                    :_destroy,
                    { batch_attributes: [
                      :id,
                      :number,
                      :day_interval,
                      :irregular_batch,
                      :_destroy,
                      { irregular_batches_attributes: %i[
                        id
                        estimated_sowing_date
                        area
                        _destroy
                      ] }
                    ] }
                  ] }
                ])
    end

    def find_scenario
      @scenario = Scenario.find(params[:id] || params[:scenario_id])
    end

  end
end
