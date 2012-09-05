class SongHash < ActiveRecord::Migration
  def change
    add_column :songs, :song_hash, :string, {null:false, default:"empty"}
    add_index :songs, :song_hash, :unique
  end
end
