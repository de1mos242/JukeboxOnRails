module AudioPlayback
	
	class AudioPlayback::MPGPlayback < AudioPlayback::PlaybackBase

	#protected

		def on_init
			@song = Linux_Song.new @music_file
		end
		
		def on_play
			@song.play
		end

		def on_resume
			@song.unpause
		end

		def on_pause
			@song.pause
		end

		def on_stop
			@song.terminate
		end

		def alive?
			system("pidof mpg123")
		end

	private
		

	end

end