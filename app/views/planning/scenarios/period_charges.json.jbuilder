# frozen_string_literal: true

json.labels human_date_labels
json.datasets %i[tools doers] do |type|
  label = type == :doers ? :workforce.tl : :equipments.tl
  charges = list_of_charge(type)
  json.label label
  json.backgroundColor Array.new(charges.count, column_color(type))
  json.data charges
end

if @day.present?
  from = Date.parse(@day).beginning_of_day
  to   = from.end_of_day
  @daily_charges.select! { |d| d.reference_date.between?(from, to) }
  json.title "#{:day_detail_of.tl} #{Date.parse(@day).strftime('%d/%m')}"
else
  json.title "#{:week_details_from.tl} #{@from.strftime('%d/%m')} #{:to.tl} #{@to.strftime('%d/%m')}"
end

%i[tools doers].each do |type|
  json.set! type do
    charges = @daily_charges.select { |d| d.product_general_type == type.to_s.singularize }
    array = charges.group_by { |c| c.product_parameter.product_nature }.map do |product_nature, charges|
      {
        type: product_nature.name,
        name: charges.first.product_parameter.procedure['name'],
        link: backend_product_nature_path(product_nature),
        quantity: charges.sum(&:quantity).round(1).in_hour.localize(precision: 1),
        available_quantity: product_nature.variants.map(&:current_stock).sum.round(2)
      }
    end
    json.merge! array.sort_by { |a| a[:name].ascii }
  end
end

json.set! :inputs do
  charges = @daily_charges.select { |d| d.product_general_type == 'input' }
  array = charges.group_by { |c| c.product_parameter.product_nature_variant }.map do |product_nature_variant, charges|
    unit = charges.first.product_parameter.unit.gsub(/_per_.*/, '')
    quantity = charges.sum(&:quantity).round(1).in(unit).l(precision: 1)
    {
      type: product_nature_variant.name,
      name: charges.first.product_parameter.procedure['name'],
      link: backend_product_nature_variant_path(product_nature_variant),
      quantity: quantity,
      available_quantity: "#{product_nature_variant.current_stock.round(1).l(precision: 1)} #{product_nature_variant.unit_name}"
    }
  end
  json.merge! array.sort_by { |a| a[:name].ascii }
end
