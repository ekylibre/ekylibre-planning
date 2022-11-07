# frozen_string_literal: true

json.human_week "#{:from.tl} #{I18n.l(@day.beginning_of_week,
                                      format: :default)} #{:to.tl} #{I18n.l(@day.end_of_week, format: :default)}"

json.interventions do
  (@day.beginning_of_week..@day.end_of_week).each_with_index do |day, index|
    proposal_hash = @intervention_proposals
                    .includes({ technical_itinerary_intervention_template: :intervention_template },
                              { activity_production: %i[activity cultivable_zone] })
                    .select { |p| p.estimated_date == day && p.intervention.nil? }
                    .map do |p|
                      intervention_template = p.technical_itinerary_intervention_template.intervention_template
                      {
                        id: p.id,
                        name: "#{intervention_template.procedure.human_name} n°#{p.number}",
                        land_parcels: [
                          {
                            name: p.activity_production.cultivable_zone.work_number,
                            color: p.activity_production.activity.color,
                            text_color: contrasted_color(p.activity_production.activity.color)
                          }
                        ],
                        type: :proposal
                      }
                    end

    planned_hash = @planned_interventions
                   .select { |intervention| intervention.started_at.to_date == day }
                   .map do |intervention|
                     {
                       id: intervention.id,
                       name: intervention.name,
                       land_parcels: intervention.decorate.land_parcels_datas(contrasted_color_callback: method(:contrasted_color)),
                       type: :planned
                     }
                   end

    json.set! index, proposal_hash + planned_hash
  end
end
json.week_days @week_days
json.day @day
json.formatted_day @day.to_time.strftime('%Y/%m/%d')
