# frozen_string_literal: true

# This migration comes from planning_engine (originally 20180306085858)
class CreateDailyCharges < ActiveRecord::Migration
  def change
    create_table :daily_charges do |t|
      t.date :reference_date
      t.string :product_type
      t.string :product_general_type
      t.decimal :quantity
      t.decimal :area
      t.references :intervention_template_product_parameter,
                   index: { name: :intervention_template_product_parameter_id }, foreign_key: true
      t.references :activity_production, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
