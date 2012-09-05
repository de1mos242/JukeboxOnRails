class Playlist
	include AudioPlayback

	@@current_song = nil
	@@has_waiter = false

	def self.refresh
		@@current_song = nil unless AudioPlayback::MPGPlayback.playing?
		unless Playlist.playing?
			Playlist.play_next
		end
	end

	def self.current_song
		@@current_song
	end

	def self.add_song(song)
		PlaylistItem.add(song)
		unless song.downloaded?
			song.download do
    			Playlist.refresh unless Playlist.playing?
  		end
		end
		Playlist.refresh
	end	

	def self.playing?
		AudioPlayback::MPGPlayback.playing?
	end

	def self.skip
		#return unless Playlist.playing?
		AudioPlayback::MPGPlayback.stop
		@@current_song = nil
		Playlist.refresh
	end

	def self.stop
		PlaylistItem.destroy_all
		Playlist.skip
	end

	def self.play_next
		return if Playlist.playing?

		next_item = PlaylistItem.downloaded.position_sorted.first
		unless next_item.nil?
			player = AudioPlayback::MPGPlayback.new next_item.song.filename
			player.play
			@@current_song = next_item.song
    		next_item.destroy
    		Playlist.shift_items
    		wait_for_stop
		end
	end

	def self.shift_items
		PlaylistItem.all.each do |item|
			item.position -= 1
			item.save
		end
	end

	def self.wait_for_stop
		return if @@has_waiter
		@@has_waiter = true
		Thread.new do
			while AudioPlayback::MPGPlayback.playing? do
				sleep 1
			end
			@@has_waiter = false
			Playlist.refresh
			Thread.exit
		end
	end
	
end