# frozen_string_literal: true

class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
