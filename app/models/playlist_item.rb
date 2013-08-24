class PlaylistItem < ActiveRecord::Base
  belongs_to :song
  #attr_accessible :position, :auto

  serialize :skip_makers, Array

  scope :with_song, -> (song) { where(song_id: song.id) }
  scope :position_sorted, -> { order("position asc") }
  scope :downloaded, -> {joins(:song).where("songs.filename is not null")}
  scope :in_queue, -> { where("position > 0") }
  scope :current_item, -> { where("position = 0") }
  scope :in_room, ->(room_id) { joins(:song).where("songs.room_id" => room_id).readonly(false) }

  def self.skips_count_limit
    Rails.application.config.common_audio_config[:skip_counter].to_i
  end
  
  def self.add(room_id, song, auto = false)
    p "add song #{song.id} in room #{room_id} auto = #{auto}"
  	unless PlaylistItem.in_room(room_id).with_song(song).first.nil?
      p "already have"
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
    item.auto = auto
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
    p "check skips: #{self.skip_counter}/#{self.class.skips_count_limit}"
    return true if self.auto and self.skip_counter > 0
    self.skip_counter >= self.class.skips_count_limit
  end

  def self.current_song(room)
    item = current_item.in_room(room).first()
    return item.song unless item.nil?
    nil
  end

end
