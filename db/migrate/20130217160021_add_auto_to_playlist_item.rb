class AddAutoToPlaylistItem < ActiveRecord::Migration
  def change
    add_column :playlist_items, :auto, :boolean
  end
end
