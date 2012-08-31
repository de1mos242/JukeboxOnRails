module AudioPlayback

	class PlaybackBase

	private
		def self.update_state
			unless @@current_song.nil?
				@@current_song = nil unless @@current_song.alive?
			end 
		end

	public

		@@current_song = nil

		def initialize(music_file)
			@music_file = music_file
			@paused = false
			on_init
		end

		def self.paused?
			@@current_song.paused
		end

		def play
			self.class.update_state

			puts "\n\n\n!!!\n!\ncheck cursong #{@@current_song}" 

			if @@current_song.nil?

				@@current_song = self

				on_play
				
				@paused = false
			end
		end

		def self.pause
			update_state
			unless @@current_song.nil?
				@@current_song.on_pause
			end
		end

		def self.stop
			update_state
			unless @@current_song.nil?
				@@current_song.on_stop
				@@current_song = nil
			end
		end

	#protected
		def on_play
			raise "Not implemented"
		end

		def on_init
		end

		def on_resume
			raise "Not implemented"
		end

		def on_pause
			raise "Not implemented"
		end

		def on_stop
			raise "Not implemented"
		end

		def alive?
			raise "Not implemented"
		end
	end

	
end