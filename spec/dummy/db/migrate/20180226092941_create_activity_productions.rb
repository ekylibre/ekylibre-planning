class CreateActivityProductions < ActiveRecord::Migration
  def change
    create_table :activity_productions do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
