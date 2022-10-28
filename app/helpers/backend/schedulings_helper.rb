# frozen_string_literal: true

module Backend
  module SchedulingsHelper
    def product_target(intervention_proposal)
      filter = intervention_proposal
               .technical_itinerary_intervention_template
               .intervention_template
               .procedure.parameters.select { |p| p.type == :target }
               .first
    end

    def product_targets(intervention_proposal)
      filter = product_target(intervention_proposal).filter
      match = filter.scan(/(?<=is\s)(\w+)/)
      match.map do |p|
        { name: p.first.underscore, human_name: I18n.t("nomenclatures.varieties.items.#{p.first.underscore}") }
      end
    end

    def product_scope(intervention_proposal)
      scope_hash = product_target_scope(intervention_proposal)
      if intervention_proposal.target?
        scope_hash[:of_expression] = "is #{intervention_proposal.target}"
        case intervention_proposal.target
        when 'land_parcel'
          scope_hash[:with_id] = intervention_proposal.activity_production.support
        when 'plant'
          scope_hash[:of_activity_production] = intervention_proposal.activity_production
        end
      elsif scope_hash[:of_expression].include?('land_parcel')
        scope_hash[:with_id] = intervention_proposal.activity_production.support
      elsif scope_hash[:of_expression].include?(' plant')
        scope_hash[:of_activity_production] = intervention_proposal.activity_production
      end
      scope_hash
    end

    def parcel_present?(intervention_proposal)
      product_target_scope(intervention_proposal)[:of_expression].include?(' plant')
    end

    def product_target_scope(intervention_proposal)
      product_target(intervention_proposal).scope_hash
    end

    def is_checked?(intervention_proposal, product_target, index)
      targets = product_targets(intervention_proposal)
      include_land_parcel = targets.select { |t| t[:name] == 'land_parcel' }.present?
      is_land_parcel = product_target[:name] == 'land_parcel'

      include_parcel = targets.select { |t| t[:name] == 'land_parcel' }.present?
      is_parcel = product_target[:name] == 'parcel'

      return true if intervention_proposal.target == product_target[:name]
      return false if !intervention_proposal.target.nil? && intervention_proposal.target != product_target[:name]
      if (include_land_parcel && is_land_parcel) || (!include_land_parcel && include_parcel && is_parcel) || index.zero?
        return true
      end

      false
    end

    def new_target_params(intervention_proposal)
      if intervention_proposal.parameters.of_product_type(:parcel).present?
        product = intervention_proposal.parameters.of_product_type(:parcel).first.product
      elsif product_target_scope(intervention_proposal)[:of_expression].include?('land_parcel')
        product = intervention_proposal.activity_production.support
      end
      { product: product }
    end

    def intervention_modal_title(intervention_proposal)
      "#{intervention_proposal.technical_itinerary_intervention_template.intervention_template.procedure.human_name}
    n°#{intervention_proposal.number}
    :
    #{intervention_proposal.technical_itinerary_intervention_template.intervention_template.name}
    -
    #{:campaign.tl}
    #{intervention_proposal.technical_itinerary_intervention_template.intervention_template.campaign.name}
    "
    end

    # get already set tool/doer in intervention proposal or
    # get it from variant / nature or
    # raise error if no one is present
    def doer_tool_product_id(type, product_parameter, intervention_proposal, index)
      if intervention_proposal.parameters.of_product_type(type.to_s.singularize)[index]
        product_id = intervention_proposal.parameters.of_product_type(type.to_s.singularize).order(:id)[index].product_id
      elsif type == :doers
        if params[:worker_id].present?
          product_id = params[:worker_id]
        elsif product_parameter.product_nature_variant && Worker.of_variant(product_parameter.product_nature_variant).any?
          product_id = Worker.of_variant(product_parameter.product_nature_variant).first.id
        elsif product_parameter.product_nature && Worker.of_nature(product_parameter.product_nature).any?
          product_id = Worker.of_nature(product_parameter.product_nature).first.id
        elsif Worker.any?
          product_id = Worker.all.first.id
        else
          raise StandardError.new('Need a least one worker. Add a worker')
        end
      elsif type == :tools
        if params[:equipment_id].present?
          product_id = params[:equipment_id]
        elsif product_parameter.product_nature_variant && Equipment.of_variant(product_parameter.product_nature_variant).any?
          product_id = Equipment.of_variant(product_parameter.product_nature_variant).first.id
        elsif product_parameter.product_nature && Equipment.of_nature(product_parameter.product_nature).any?
          product_id = Equipment.of_nature(product_parameter.product_nature).first.id
        elsif Equipment.any?
          product_id = Equipment.all.first.id
        else
          raise StandardError.new('Need a least one equipment. Add an equipment')
        end
      end
      product_id
    end

    def interventions_proposals_chronology_icons(interventions_list, _period_started_on, _duration, html_options = {})
      code = ''
      interventions_list.each do |week_number, interventions|
        html_options[:url] = nil
        now = Date.today
        marked_date = nil

        html_options[:data] = {}
        html_options[:class] = nil

        if interventions.map(&:class).uniq.count <= 1
          interventions.each do |intervention|
            html_options[:url] = backend_intervention_path(intervention)
            marked_date = intervention.instance_of?(Intervention) ? intervention.started_at.to_date : intervention.estimated_date
          end
          code += generate_icon(interventions, week_number, marked_date, html_options)
        else
          interventions.group_by(&:class).each do |grouped_interventions|
            if grouped_interventions[0] == Intervention
              grouped_interventions[1].group_by(&:nature).each do |grouped_interventions|
                grouped_interventions[1].each do |intervention|
                  html_options[:url] = backend_intervention_path(intervention)
                  marked_date = intervention.instance_of?(Intervention) ? intervention.started_at.to_date : intervention.estimated_date
                end
                code += generate_icon(grouped_interventions[1], week_number, marked_date, html_options)
              end
            else
              grouped_interventions[1].each do |intervention|
                html_options[:url] = backend_intervention_path(intervention)
                marked_date = intervention.instance_of?(Intervention) ? intervention.started_at.to_date : intervention.estimated_date
              end
              code += generate_icon(grouped_interventions[1], week_number, marked_date, html_options)
            end
          end
        end
      end

      code.html_safe
    end

    def generate_icon(interventions, week_number, marked_date, html_options)
      if interventions.count > 1
        year = interventions
               .map { |intervention| intervention.try(:started_at).nil? ? intervention.estimated_date : intervention.started_at }
               .map(&:year)
               .uniq
               .first

        week_begin_date = Date.commercial(year, week_number, 1)
        if interventions.map { |i| i.class.to_s }.exclude?('InterventionProposal')
          html_options[:url] =
            backend_interventions_path(current_period: week_begin_date.to_s, current_period_interval: 'week')
        else
          html_options[:data][:intervention_proposal_week] = week_begin_date.to_s
          html_options[:class] = 'marker orange week-proposal'
        end
        marked_date ||= week_begin_date
      end

      positioned_at = (marked_date - @period_started_on).to_f / @duration * 0.92

      if interventions.map { |i| i.class.to_s }.exclude?('InterventionProposal')
        if interventions.map(&:nature).include?('record')
          html_options[:class] = 'marker green'
          intervention_icon = 'check'
        else
          html_options[:class] = 'marker yellow'
          intervention_icon = 'clock'
        end
      else
        unless html_options[:class]&.include?('week-proposal')
          html_options[:class] =
            'marker orange open-modal'
        end
        intervention_icon = 'question'

        html_options[:url] = nil
        html_options[:data].merge!({ proposal_id: interventions.last.id })
      end

      html_options['data-toggle'] = 'tooltip'
      html_options[:title] = interventions.sort_by do |i|
        i.instance_of?(Intervention) ? i.started_at : i.estimated_date
      end.map(&:name).join(', ')
      chronology_period_icon(positioned_at, intervention_icon, html_options)
    end
  end
end
