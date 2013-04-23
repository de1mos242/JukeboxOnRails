class SongInRoom < ActiveRecord::Migration
  def up
    add_column :songs, :room, :integer
    Song.all.each do |song|
      song.room = 1
      song.save!
    end
  end

  def down
    remove_column :songs, :room
  end
end
