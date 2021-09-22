# frozen_string_literal: true

# This migration comes from planning_engine (originally 20180330120700)
class AddDataToInterventionProposalTable < ActiveRecord::Migration
  def change
    # I18n.locale = Entity.of_company.language.to_sym
    ActivityProduction.where.not(technical_itinerary: nil).each(&:save) unless I18n.locale == :afr
  end
end
