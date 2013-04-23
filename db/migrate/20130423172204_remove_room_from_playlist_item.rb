class RemoveRoomFromPlaylistItem < ActiveRecord::Migration
  def up
    remove_column :playlist_items, :room
  end

  def down
    add_column :playlist_items, :room, :integer
  end
end
