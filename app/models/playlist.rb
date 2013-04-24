rails_root = File.expand_path('../../..', __FILE__)
require 'eventmachine'
require "#{rails_root}/lib/mq/base_queue"

class Playlist
	include AudioPlayback

  def self.prepare_players
    @players = {}
    Room.all.each do |room|
      @players[room.id] = AudioPlayback::GStreamPlayback.new(room.id)
    end
    p @players.inspect
  end

  prepare_players

  def self.get_data(room)
    data = {}
    data[:playlist_items] = PlaylistItem.position_sorted.in_queue.in_room(room).all
    data[:current_song] = PlaylistItem.current_song(room)
    data
  end

  def self.prepare_longpoll_message(room, timestamp)
    new_data = get_data(room)
    result = '{'
    result += "\"playlist_items\": #{new_data[:playlist_items].to_json(include: {song: {only: [:artist, :title, :duration]}}).html_safe},"
    result += "\"current_song\": #{new_data[:current_song].to_json(only: [:artist, :title, :duration]).html_safe},"
    result += "\"last_update\": \"#{timestamp}\""
    result += '}'
    result
  end

  def self.push_to_longpoll(room)
    update_ts = Time.now.to_r.to_s
    MessageQueue::BaseQueue.SendBroadcastMessage("longpoll.refresh", {update_ts: update_ts, room: room}, prepare_longpoll_message(room, update_ts))
  end
	
	def self.refresh(room=nil)
		if room
      refresh_room(room)
    else
      @players.each_key { | room_id | refresh_room(room_id)}
    end
  end

  def self.refresh_room(room)
    p "on refresh #{room}"
    unless playing? (room)
      p 'do play_next'
      play_next(room)
      unless playing?(room) # instead of play silence play random song from cache
        play_random(room)
      end
    end
    push_to_longpoll(room)
  end

	def self.current_song(room)
		playlist_item = current_playlist_item(room)
		return playlist_item.song unless playlist_item.nil?
		nil
	end

	def self.current_playlist_item(room)
		PlaylistItem.current_item.in_room(room).first()
	end

	def self.add_song(room, song, auto = false)
		PlaylistItem.add(room, song, auto)
		unless song.downloaded?
			start_download = Proc.new do 
				puts "#{song.artist} - #{song.title} run async download"
				song.download
			end
			on_download = Proc.new do |filename|
				puts "#{song.artist} - #{song.title} #{filename} downloaded callback"
				song.filename = filename
				song.save!
				refresh(room)
			end
			EM.defer(start_download, on_download)
    end
    refresh(room)
	end	

	def self.playing?(room)
    p "is playing? for #{room}"
    @players[room].playing?
	end

	def self.skip(room)
		p "on skip"
    @players[room].stop if playing?
		#refresh
		p "skip finished"
	end

	def self.stop(room)
		PlaylistItem.in_room(room).destroy_all
		skip(room)
	end

	def self.play_next(room)
		p "on play_next"
		return if playing?(room)
		p "play_next song"
		next_item = PlaylistItem.downloaded.in_room(room).position_sorted.in_queue.first
		unless next_item.nil?
			p "next_item found"
			p "kick player in room #{room}: #{next_item.position}: #{next_item.song.artist} - #{next_item.song.title}"
      @players[room].play_song({
				filename: next_item.song.filename, 
				artist: next_item.song.artist, 
				title: next_item.song.title}) do 
					p "refresh callback from player"
					refresh(room)
				end
			p "shift after play_next"
			shift_items(room, next_item)
		else
			shift_items(room) unless current_playlist_item(room).nil?
	  end
	end

	def self.shift_items(room, new_play_item = nil)
		p "shift elements #{new_play_item}"
		PlaylistItem.in_room(room).where("position <= 0").each {|item| item.destroy }
		if new_play_item && new_play_item.position > 1
			item = PlaylistItem.find(new_play_item.id) # prevent read-only record
			item.position = 0
			item.save!
		elsif PlaylistItem.in_room(room).downloaded.size == 0 && PlaylistItem.in_room(room).size > 0
			#do nothing
			p "we have in downloaded queue"
		else
			PlaylistItem.in_room(room).each do |item|
				item.position -= 1
				item.save!
			end
		end
		p "new items:"
		PlaylistItem.in_room(room).each { |item| p "  #{item.position}: #{item.song.artist} - #{item.song.title}" }
  end

  def self.play_random(room)
    cached_songs = Song.downloaded.in_room(room).all
    add_song(room, cached_songs[rand(cached_songs.length)], true) unless cached_songs.empty?
  end

end