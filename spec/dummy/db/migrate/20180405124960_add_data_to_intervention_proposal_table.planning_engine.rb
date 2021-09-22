# frozen_string_literal: true

# This migration comes from planning_engine (originally 20180330120700)
class AddDataToInterventionProposalTable < ActiveRecord::Migration
  def change
    ActivityProduction.where.not(technical_itinerary: nil).each(&:save)
  end
end
