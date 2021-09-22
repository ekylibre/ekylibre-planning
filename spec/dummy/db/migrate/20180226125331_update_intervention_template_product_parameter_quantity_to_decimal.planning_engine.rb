# frozen_string_literal: true

# This migration comes from planning_engine (originally 20180126094309)
class UpdateInterventionTemplateProductParameterQuantityToDecimal < ActiveRecord::Migration
  def self.up
    change_column :intervention_template_product_parameters, :quantity, :decimal
  end

  def self.down
    change_column :intervention_template_product_parameters, :quantity, :integer
  end
end
