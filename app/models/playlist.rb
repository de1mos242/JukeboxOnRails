class Playlist
	include AudioPlayback

	def self.refresh
		p "on refresh"
		return if playing?
		p 'do play_next'
		play_next
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
			song.download do
    			refresh
  			end
  		else
  			refresh
		end
	end	

	def self.playing?
		AudioPlayback::GStreamPlayback.playing?
	end

	def self.skip
		p "on skip"
		AudioPlayback::GStreamPlayback.stop
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