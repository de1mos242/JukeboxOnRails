class PlaylistSongIdUnique < ActiveRecord::Migration
  def up
  	remove_index "playlist_items", column: "song_id"
  	add_index "playlist_items", ["song_id"], :name => "index_playlist_items_on_song_id", :unique => true
  	
  end

  def down
  	remove_index "playlist_items", column: "song_id"
  	add_index "playlist_items", ["song_id"], :name => "index_playlist_items_on_song_id"
  end
end
