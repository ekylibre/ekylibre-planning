class CreateProductNatures < ActiveRecord::Migration
  def change
    create_table :product_natures do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
