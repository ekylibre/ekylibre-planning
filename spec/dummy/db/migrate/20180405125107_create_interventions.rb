# frozen_string_literal: true

class CreateInterventions < ActiveRecord::Migration
  def change
    create_table :interventions do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
