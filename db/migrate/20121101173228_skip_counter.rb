class SkipCounter < ActiveRecord::Migration
  def change
	add_column :playlist_items, :skip_counter, :integer, {null:false, default:0}
	add_column :playlist_items, :skip_makers, :text
  end
end
