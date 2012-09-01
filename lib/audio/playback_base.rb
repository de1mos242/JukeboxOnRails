module AudioPlayback

	class PlaybackBase
		@@current_song = nil
		
	private
		def self.update_state
			unless @@current_song.nil?
				@@current_song = nil unless @@current_song.alive?
			end 
		end

	public

		def self.set_volume(value)
			raise "Not implemented"
		end

		def self.get_current_volume
			raise "Not implemented"
		end
		
		def self.playing?
			update_state
			not @@current_song.nil?
		end

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

			unless @@current_song.nil?
				@@current_song.on_stop
				@@current_song = nil
			end

			@@current_song = self

			on_play
				
			@paused = false
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