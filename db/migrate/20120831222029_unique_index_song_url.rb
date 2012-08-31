class UniqueIndexSongUrl < ActiveRecord::Migration
  def change
  	add_index(:songs, :url, :unique => true)
  end
end
