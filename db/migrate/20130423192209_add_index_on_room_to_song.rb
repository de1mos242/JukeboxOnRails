class AddIndexOnRoomToSong < ActiveRecord::Migration
  def change
    add_index :songs, [:room]
  end
end
