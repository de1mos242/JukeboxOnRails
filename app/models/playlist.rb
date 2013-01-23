rails_root = File.expand_path('../../..', __FILE__)
require 'eventmachine'
require "#{rails_root}/lib/mq/base_queue"
class Playlist
	include AudioPlayback

  def self.get_data
    data = {}
    data[:playlist_items] = PlaylistItem.position_sorted.in_queue.all
    data[:current_song] = PlaylistItem.current_song
    data
  end

  def self.prepare_longpoll_message(timestamp)
    new_data = get_data
    result = '{'
    result += "\"playlist_items\": #{new_data[:playlist_items].to_json(include: {song: {only: [:artist, :title, :duration]}}).html_safe},"
    result += "\"current_song\": #{new_data[:current_song].to_json(only: [:artist, :title, :duration]).html_safe},"
    result += "\"last_update\": \"#{timestamp}\""
    result += '}'
    result
  end

  def self.push_to_longpoll
    update_ts = Time.now.to_r.to_s
    MessageQueue::BaseQueue.SendBroadcastMessage("longpoll.refresh", {update_ts: update_ts}, prepare_longpoll_message(update_ts))
  end
	
	def self.refresh
		p "on refresh"
		unless playing?
		  p 'do play_next'
		  play_next
    end
    push_to_longpoll
	end

	def self.current_song
		playlist_item = current_playlist_item
		return playlist_item.song unless playlist_item.nil?
		nil
	end

	def self.current_playlist_item
		PlaylistItem.current_item.first()
	end

	def self.add_song(song)
		PlaylistItem.add(song)
		unless song.downloaded?
			start_download = Proc.new do 
				puts "#{song.artist} - #{song.title} run async download"
				song.download
			end
			on_download = Proc.new do |filename|
				puts "#{song.artist} - #{song.title} #{filename} downloaded callback"
				song.filename = filename
				song.save!
				refresh
			end
			EM.defer(start_download, on_download)
  		else
  			refresh
		end
	end	

	def self.playing?
		AudioPlayback::GStreamPlayback.playing?
	end

	def self.skip
		p "on skip"
		AudioPlayback::GStreamPlayback.stop if playing?
		#refresh
		p "skip finished"
	end

	def self.stop
		PlaylistItem.destroy_all
		skip
	end

	def self.play_next
		p "on play_next"
		return if playing?
		p "play_next song"
		next_item = PlaylistItem.downloaded.position_sorted.in_queue.first
		unless next_item.nil?
			p "next_item found"
			p "kick player: #{next_item.position}: #{next_item.song.artist} - #{next_item.song.title}"
			AudioPlayback::GStreamPlayback.play_song({
				filename: next_item.song.filename, 
				artist: next_item.song.artist, 
				title: next_item.song.title}) do 
					p "refresh callback from player"
					refresh
				end
			p "shift after play_next"
			shift_items(next_item)
		else
			shift_items unless current_playlist_item.nil?
	    end
	end

	def self.shift_items(new_play_item = nil)
		p "shift elements #{new_play_item}"
		PlaylistItem.where("position <= 0").each {|item| item.destroy }
		if new_play_item && new_play_item.position > 1
			item = PlaylistItem.find(new_play_item.id) # prevent read-only record
			item.position = 0
			item.save!
		elsif PlaylistItem.downloaded.size == 0 && PlaylistItem.all.size > 0
			#do nothing
			p "we have in downloaded queue"
		else
			PlaylistItem.all.each do |item|
				item.position -= 1
				item.save!
			end
		end
		p "new items:"
		PlaylistItem.all.each { |item| p "  #{item.position}: #{item.song.artist} - #{item.song.title}" }
  end

end