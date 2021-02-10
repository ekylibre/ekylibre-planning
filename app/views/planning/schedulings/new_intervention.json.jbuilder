json.intervention_proposal do
  json.name "#{ @intervention_proposal.technical_itinerary_intervention_template.intervention_template.procedure.human_name }
  n°#{ @intervention_proposal.number }
  :
  #{ @intervention_proposal.technical_itinerary_intervention_template.intervention_template.name }
  -
  #{ :campaign.tl }
  #{ @intervention_proposal.technical_itinerary_intervention_template.intervention_template.campaign.name }
  "
  json.date @intervention_proposal.estimated_date.l
  json.estimated_working_time  @intervention_proposal.human_estimated_working_time
  json.activity do
    activity = @intervention_proposal.technical_itinerary_intervention_template.technical_itinerary.activity
    json.name activity.name
    json.background_color activity.color
    json.color contrasted_color(activity.color)
  end
  json.parcel @intervention_proposal.activity_production.support.name


  filter = @intervention_proposal
  .technical_itinerary_intervention_template
  .intervention_template
  .procedure.parameters_of_type(:target)
  .first
  .filter

  json.targets Product.of_expression(filter).pluck(:type).uniq.map { |p| { name: p.underscore, human_name: p.underscore.tl }}

end
