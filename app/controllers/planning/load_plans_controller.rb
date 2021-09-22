module Planning
  class LoadPlansController < Planning::ApplicationController
    def index
      @activity_productions = ActivityProduction.with_technical_itinerary
      respond_to do |format|
        format.html
        format.json
      end
    end

    def period_charges
      period_params
      weekly_period = false

      if @week.present?
        @from = Date.parse(@week)
        @to = @from.end_of_week
      else
        @from = get_year_start_week(@now)
        @to   = @now.end_of_year.end_of_week
        weekly_period = true
      end

      get_daily_charges
      get_labels(@from, @to, weekly_period)
      respond_to do |format|
        format.json
      end
    end

    def period_charges_details
      period_params
      if @week.present?
        @from = Date.parse(@week)
        @to   = @from.end_of_week
      elsif @day.present?
        @from = Date.parse(@day).beginning_of_day
        @to   = @from.end_of_day
      end
      get_daily_charges
      respond_to do |format|
        format.json
      end
    end

    private

    def period_params
      @now = params[:year].present? ? "01/01/#{params[:year]}".to_date : Time.now
      year = @now.year
      @week = params[:week]&.insert(-1, "/#{year}")
      @day = params[:day]&.insert(-1, "/#{year}")
    end

    def get_daily_charges
      @daily_charges = DailyCharge.between_date(@from, @to).of_activity(params[:activity_id])
    end

    def get_year_start_week(time)
      week_beginning = time.beginning_of_year.beginning_of_week
      if week_beginning.year < time.year
        week_beginning.next_week
      else
        week_beginning
      end
    end

    # Return an array of date (format: dd/mm) wich are the start of all weeks in the period
    def get_labels(from, to, weekly_period)
      @labels = []
      while from <= to
        @labels << from
        from = if weekly_period
                 from.next_week
               else
                 from + 1.day
               end
      end
      @labels
    end
  end
end
