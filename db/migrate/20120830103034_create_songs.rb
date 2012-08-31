class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :artist
      t.string :title
      t.string :url
      t.string :filename

      t.timestamps
    end
    add_index :songs, :artist
    add_index :songs, :title
  end
end
