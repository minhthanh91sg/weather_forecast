class AddPostCodeLocationToStation < ActiveRecord::Migration
  def change
    add_reference :stations, :post_code_location, index: true
    add_foreign_key :stations, :post_code_locations
  end
end
