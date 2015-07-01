class CreatePostCodeLocations < ActiveRecord::Migration
  def change
    create_table :post_code_locations do |t|
      t.float :lat
      t.float :long

      t.timestamps null: false
    end
  end
end
