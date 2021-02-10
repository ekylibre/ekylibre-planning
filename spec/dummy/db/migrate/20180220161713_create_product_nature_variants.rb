class CreateProductNatureVariants < ActiveRecord::Migration
  def change
    create_table :product_nature_variants do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
