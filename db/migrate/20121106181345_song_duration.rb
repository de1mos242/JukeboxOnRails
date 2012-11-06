class SongDuration < ActiveRecord::Migration
  def change
  	add_column :songs, :duration, :text
  end
end
