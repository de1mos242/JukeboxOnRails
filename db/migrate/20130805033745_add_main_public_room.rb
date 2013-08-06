class AddMainPublicRoom < ActiveRecord::Migration
  def up
  	add_column :rooms, :main_room, :boolean
  	add_index :rooms, :main_room
  	Room.destroy_all
  	room = Room.new
  	room.name = "Main room"
  	room.public_room = true
  	room.main_room = true
  	room.save!

  	Song.find(:all).each do |song|
  		song.room = room
  		song.save!
  	end
  end
end
