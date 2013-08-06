class AddPublicToRooms < ActiveRecord::Migration
  def change
  	add_column :rooms, :public_room, :boolean
  	add_index :rooms, :public_room
  end
end
