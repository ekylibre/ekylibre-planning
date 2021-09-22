# frozen_string_literal: true

module Backend
  module InterventionTemplatesHelper
    def procedure_parameters(procedure)
      procedure.parameters.map do |p|
        next unless p.class != Procedo::Procedure::GroupParameter && !p.target?

        { name: p.human_name,
          expression: p.scope_hash,
          type: p.name,
          unities: list_of_unities(p),
          is_tool_or_doer: p.tool? || p.doer? }
      end.compact
    end

    def list_of_unities(param)
      if param.tool? || param.doer?
        { human_name: :unit.tl, name: :unit }
      else
        param.handlers.map do |handler|
          if handler.population?
            { human_name: Onoma::Unit.find(:unity).human_name, name: handler.name }
          elsif handler.widget == :number
            unit = handler.unit? ? handler.unit : Onoma::Unit.find(:unity)
            { human_name: "#{unit.symbol} (#{handler.human_name})", name: handler.name }
          end
        end
      end
    end

    def association_activities_list
      @intervention_template.association_activities.each do |a|
        a.activity_label = (a.activity&.name if a.activity.present?)
      end.to_json
    end

    def product_parameters_list
      @intervention_template.product_parameters.each do |i|
        i.product_name = i.product_nature&.name || i.product_nature_variant&.name
      end.to_json
    end

    def product_parameter_picto(product_parameter)
      pictogram = if product_parameter.product_nature_variant.present?
                    product_parameter.product_nature_variant.category.pictogram
                  elsif product_parameter.product_nature.from_nomenclature?
                    category_label = Onoma::ProductNature.find(product_parameter.product_nature.reference_name).category
                    Onoma::ProductNatureCategory.find(category_label).pictogram
                  else
                    category = product_parameter.product_nature.variants.group(:category).order('count_all DESC').limit(1).count.keys.first
                    category&.pictogram
                  end

      pictogram ||= 'question'

      content_tag(:div, '', class: ['picto', "picto-#{pictogram}"])
    end

    def product_parameter_name_link(product_parameter)
      procedure_name = product_parameter.procedure['name']

      if product_nature = product_parameter.product_nature
        link_to(procedure_name,
                { controller: "backend/#{product_nature.class.table_name}", action: :show, id: product_nature.id })
      else
        product_nature_variant = product_parameter.product_nature_variant
        link_to(procedure_name,
                { controller: "backend/#{product_nature_variant.class.table_name}",
                  action: :show,
                  id: product_nature_variant.id })
      end
    end
  end
end
