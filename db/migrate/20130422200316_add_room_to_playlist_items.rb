class AddRoomToPlaylistItems < ActiveRecord::Migration
  def change
    add_column :playlist_items, :room, :integer
  end
end
