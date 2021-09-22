# frozen_string_literal: true

class AddStartedOnAndStoppedOnToActivityProduction < ActiveRecord::Migration
  def change
    add_column :activity_productions, :started_on, :date
    add_column :activity_productions, :stopped_on, :date
  end
end
