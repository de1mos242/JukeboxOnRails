class PlaylistItem < ActiveRecord::Base
  belongs_to :song
  attr_accessible :position

  scope :with_song, lambda { |song| {conditions: ['song_id = ?', song.id]} }
  scope :position_sorted, order: "position asc" 
  scope :downloaded, joins(:song).where("songs.filename is not null")
  
  def self.add(song)
  	unless PlaylistItem.with_song(song).first.nil?
  		return nil
  	end

  	item_position = 1
  	last_item = PlaylistItem.order("position desc").first
  	unless last_item.nil?
  	 	item_position = last_item.position+1
  	end
  	item = PlaylistItem.new
  	item.position = item_position
  	item.song = song
  	item.save
  	item
  end
end
