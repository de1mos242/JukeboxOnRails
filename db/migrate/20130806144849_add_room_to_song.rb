class AddRoomToSong < ActiveRecord::Migration
  def up
  	add_column :songs, :room_id, :integer
  	add_index :songs, :room_id
  	remove_index :songs, :room
  	remove_column :songs, :room

  	main_room = Room.get_main_room
  	Song.find(:all).each do |song|
  		song.room = main_room
  		song.save!
  	end
  end
end
