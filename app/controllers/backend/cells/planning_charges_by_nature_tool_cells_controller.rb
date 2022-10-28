module Backend
  module Cells
    class PlanningChargesByNatureToolCellsController < Backend::Cells::BaseController
      include ChartsHelper

      TOOLS_BAR_COLOR = '#64B5F6'
      DOERS_BAR_COLOR = '#AED581'

      HOVERED_TOOLS_BAR_COLOR = '#5FB3F3'
      HOVERED_DOERS_BAR_COLOR = '#99E65B'

      HIGHLIGHTED_TOOLS_BAR_COLOR = '#01579B'
      HIGHLIGHTED_DOERS_BAR_COLOR = '#33691E'

      def show
        @title_cel = :planning_charges_by_nature_tool_cell_title.tl
        @campaign = current_campaign
        # items = EconomicCashIndicator.of_campaign(@campaign).reorder(:used_on)
        # @fy = current_financial_year
        stopped_on = Date.new(@campaign.harvest_year, 12, 31)
        started_on = Date.new(@campaign.harvest_year, 1, 1)
        items = DailyCharge.between_date(started_on, stopped_on).of_type('tool')
        tool_natures = items.map(&:product_nature).compact.uniq
        @title = "#{started_on.l} - #{stopped_on.l}"

        tool_nature_data = []
        tool_variant_data = []
        @series = []
        if items.any?
          tool_natures.each do |tool_nature|
            sum_nature_hour = items.of_nature(tool_nature).sum(:quantity).round(2)
            tool_nature_data << { name: tool_nature.name, y: sum_nature_hour.to_s.to_f, id: tool_nature.id, url: backend_product_nature_path(tool_nature) }
            tool_variants = items.of_nature(tool_nature).map(&:product_nature_variant).compact.uniq
            tool_variants.each do |tool_variant|
              sum_hour = items.of_variant(tool_variant).sum(:quantity).round(2)
              tool_variant_data << { name: tool_variant.name, y: sum_hour.to_s.to_f, url: backend_product_nature_variant_path(tool_variant) }
            end
          end
          @series << {name: ProductNature.model_name.human, data: tool_nature_data, size: "60%", data_labels: {enabled: false}}
          @series << {name: ProductNatureVariant.model_name.human, data: tool_variant_data, size: "80%", inner_size: "60%", data_labels: {enabled: true}}
        end
        @tooltip_options = build_tooltip_options
        @plot_options = build_plot_options
        @series
      end

      private

        def build_tooltip_options
          { point_format: "{point.y: 1.2f} H" }
        end

        def build_plot_options
          { allow_point_select: true, cursor: 'pointer' }
        end

    end
  end
end
