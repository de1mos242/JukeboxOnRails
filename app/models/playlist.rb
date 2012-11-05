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
    			refresh unless playing?
  			end
		end
		refresh
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
			AudioPlayback::GStreamPlayback.play_file next_item.song.filename do 
				p "refresh callback from player"
				refresh
			end
    	end
    	p "shift after play_next"
		shift_items
	end

	def self.shift_items
		p "shift elements"
		PlaylistItem.all.each do |item|
			item.position -= 1
			if item.position >= 0
				item.save!
			else
				item.destroy
			end
		end
		p "new items:"
		PlaylistItem.all.each { |item| p "  #{item.position}: #{item.song.artist} - #{item.song.title}" }
	end
end