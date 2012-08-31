class CreatePlaylistItems < ActiveRecord::Migration
  def change
    create_table :playlist_items do |t|
      t.references :song
      t.integer :position

      t.timestamps
    end
    add_index :playlist_items, :song_id
  end
end
