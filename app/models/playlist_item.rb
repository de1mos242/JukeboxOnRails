class PlaylistItem < ActiveRecord::Base
  belongs_to :song
  attr_accessible :position

  serialize :skip_makers, Array

  scope :with_song, lambda { |song| {conditions: ['song_id = ?', song.id]} }
  scope :position_sorted, order: "position asc" 
  scope :downloaded, joins(:song).where("songs.filename is not null")
  scope :in_queue, conditions: "position > 0"
  scope :current_item, conditions: "position = 0"

  def self.skips_count_limit
    Rails.application.config.common_audio_config[:skip_counter]
  end
  
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
    item.skip_makers = []
  	item.save
  	item
  end

  def add_skip_wish(user_data)
    p "skip_makers #{self.skip_makers}"
    return 0 if skip_makers.include?(user_data)
    self.skip_counter += 1
    self.skip_makers << user_data

    save!
  end

  def skipped?()
    self.skip_counter >= self.class.skips_count_limit
  end
end
