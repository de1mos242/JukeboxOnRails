class SongInRoom < ActiveRecord::Migration
  def up
    add_column :songs, :room, :integer
  end

  def down
    remove_column :songs, :room
  end
end
