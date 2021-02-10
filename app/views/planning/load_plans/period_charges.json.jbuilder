json.labels human_date_labels
json.datasets %i(tools doers) do |type|
  label = type == :doers ? :workforce.tl : :equipments.tl
  charges = list_of_charge(type)

  json.label label
  json.backgroundColor Array.new(charges.count, column_color(type))
  json.data charges
end

if @day.present?
  json.title "#{:day_detail_of.tl} #{@from.strftime('%d/%m')}"
else
  json.title "#{:week_details_from.tl} #{@from.strftime('%d/%m')} #{:to.tl} #{@to.strftime('%d/%m')}"
end

%i(tools doers).each do |type|
  json.set! type do
    array = @daily_charges
            .of_type(type.to_s.singularize)
            .includes(product_parameter: %i[product_nature product_nature_variant])
            .references(product_parameter: %i[product_nature product_nature_variant])
            .group('product_natures.id')
            .pluck(
              'product_natures.id AS id',
              'product_natures.name AS type',
              "(ARRAY_AGG(intervention_template_product_parameters.procedure -> 'name'))[1] AS name",
              'ROUND(SUM(daily_charges.quantity), 1) AS quantity'
            ).map do |id, type, name, quantity|
              {
                type: type,
                name: name,
                quantity: quantity.in_hour.localize(precision: 1),
                link: backend_product_nature_path(id),
                available_quantity: ProductNature.find(id).variants.map(&:current_stock).sum.round(2)
              }
            end
    json.merge! array.sort_by { |a| a[:name].ascii }
  end
end

json.set! :inputs do
  array = @daily_charges
          .of_type('input')
          .includes(product_parameter: %i[product_nature product_nature_variant])
          .references(product_parameter: %i[product_nature product_nature_variant])
          .group('product_nature_variants.id')
          .pluck(
            'product_nature_variants.id AS id',
            'product_nature_variants.name AS type',
            "(ARRAY_AGG(intervention_template_product_parameters.procedure -> 'name'))[1] AS name",
            'ROUND(SUM(daily_charges.quantity), 1) AS quantity',
            '(ARRAY_AGG(intervention_template_product_parameters.unit))[1] AS unit'
          ).map do |id, type, name, quantity, unit|
            product_nature_variant = ProductNatureVariant.find(id)
            unit = unit.gsub(/_per_.*/, '')
            {
              type: type, name: name,
              quantity: quantity.in(unit).l(precision: 1),
              link: backend_product_nature_variant_path(id),
              available_quantity: "#{product_nature_variant.current_stock.round(1).l(precision: 1)} #{product_nature_variant.unit_name}"
            }
          end
  json.merge! array.sort_by { |a| a[:name].ascii }
end
