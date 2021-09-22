# frozen_string_literal: true

if @day.present?
  json.title "#{:day_detail_of.tl} #{@from.strftime('%d/%m')}"
else
  json.title "#{:week_details_from.tl} #{@from.strftime('%d/%m')} #{:to.tl} #{@to.strftime('%d/%m')}"
end

%i[tools doers].each do |type|
  json.set! type do
    charges = @daily_charges.of_type(type.to_s.singularize).includes(:product_parameter)
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
  charges = @daily_charges.of_type('input').includes(:product_parameter)
  array = charges.group_by { |c| c.product_parameter.product_nature_variant }.map do |product_nature_variant, charges|
    unit = charges.first.product_parameter.unit.gsub(/_per_.*/, '')
    {
      type: product_nature_variant.name,
      name: charges.first.product_parameter.procedure['name'],
      link: backend_product_nature_variant_path(product_nature_variant),
      quantity: charges.sum(&:quantity).round(1).in(unit).l(precision: 1),
      available_quantity: "#{product_nature_variant.current_stock.round(1).l(precision: 1)} #{product_nature_variant.unit_name}"
    }
  end
  json.merge! array.sort_by { |a| a[:name].ascii }
end
