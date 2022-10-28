module Backend
  module Cells
    class PlanningChargesByActivityCellsController < Backend::Cells::BaseController
      include ChartsHelper

      TOOLS_BAR_COLOR = '#64B5F6'
      DOERS_BAR_COLOR = '#AED581'

      HOVERED_TOOLS_BAR_COLOR = '#5FB3F3'
      HOVERED_DOERS_BAR_COLOR = '#99E65B'

      HIGHLIGHTED_TOOLS_BAR_COLOR = '#01579B'
      HIGHLIGHTED_DOERS_BAR_COLOR = '#33691E'

      def show
        @title_cel = :planning_charges_by_activity_cell_title.tl
        @description_cel = :planning_charges_by_activity_cell_line_1.tl + "\n" + :planning_charges_by_activity_cell_line_2.tl + "\n"
        @description_cel += :planning_charges_by_activity_cell_line_3.tl + "\n" + :planning_charges_by_activity_cell_line_4.tl
        @campaign = current_campaign
        # items = EconomicCashIndicator.of_campaign(@campaign).reorder(:used_on)
        # @fy = current_financial_year
        stopped_on = Date.new(@campaign.harvest_year, 12, 31)
        started_on = Date.new(@campaign.harvest_year, 1, 1)
        items = DailyCharge.between_date(started_on, stopped_on).reorder(:reference_date)
        activity_ids = items.pluck(:activity_id).uniq
        @series = []
        @drilldown = {}
        @drilldown[:series] = []
        @title = "#{started_on.l} - #{stopped_on.l}"
        if items.any?
          @categories = first_day_of_months_between(started_on, stopped_on)

          # build global balance for all items
          balance_tool_data = []
          balance_doer_data = []
          balance_collection = items.group_by { |item| item.reference_date.beginning_of_month.to_date }
          month_tool_balance = 0.0
          month_doer_balance = 0.0
          @categories.each do |categorie|
            balance_items = balance_collection.select{ |k, v| k == categorie}
            if balance_items.any?
              month_tool_balance = balance_items.values.flatten.select{ |n| n.product_general_type == 'tool'}.sum(&:quantity)
              month_doer_balance = balance_items.values.flatten.select{ |n| n.product_general_type == 'doer'}.sum(&:quantity)
            end
            balance_tool_data << month_tool_balance.round(2).to_s.to_f
            balance_doer_data << month_doer_balance.round(2).to_s.to_f
          end
          @series << { type: 'spline', name: :balance_tool.tl, data: balance_tool_data, marker: {line_width: 2} }
          @series << { type: 'spline', name: :balance_doer.tl, data: balance_doer_data, marker: {line_width: 2} }

          @categories.each do |category|
            month_dataset = items.between_date(category.beginning_of_month, category.end_of_month).reorder(:reference_date)
            @drilldown[:series] << build_data_drilldown(category, month_dataset)
          end

          # build revenue & expenses by month for each context (activities, worker_contract, loan)
          activity_ids.each do |activity_id|
            activity = Activity.find(activity_id)
            color = activity.color

            dataset = items.of_activity(activity).of_type(['doer','tool']).reorder(:reference_date)

            @series << create_serie_for(dataset, @categories, activity.name, color) if dataset.any?
          end
        end
        @drilldown
        @series
      end

      private

        def create_serie_for(collection, categories, name, color)
          grouped_collection = collection.group_by { |item| item.reference_date.beginning_of_month.to_date }
          data = grouped_collection.map { |k, v| [k, v.map{ |i|  i.quantity }.compact.sum.round(2)]}.sort.to_h
          chart_data = fill_values categories, data, name, empty_value: nil

          { type: 'column', name: name, data: chart_data, color: color} # stack: direction
        end

        def first_day_of_months_between(started_on, stopped_on)
          res = started_on.beginning_of_month
          categories = []

          while res < stopped_on
            categories << res
            res += 1.month
          end

          categories
        end

        def fill_values(categories, values, name, empty_value:)
          categories.map do |date|
            { name: name, y: values.fetch(date, empty_value).to_f.round(2), drilldown: date.to_s }
          end
        end

        # see https://api.highcharts.com/highcharts/series.packedbubble for more details
        def build_data_drilldown(category, dataset)
          data = []
          dataset.each do |item|
            if item[:product_general_type] == 'doer'
              # y = -1.0
              color = DOERS_BAR_COLOR
            else
              # y = 1.0
              color = TOOLS_BAR_COLOR
            end
            data <<  { name: item[:product_type], data_labels: { format: '{point.name}' }, value: item[:quantity].round(2).to_s.to_f, color: color }
          end

          { id: category.to_s, type: 'packedbubble', data: data }

        end
    end
  end
end
