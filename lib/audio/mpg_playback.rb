module AudioPlayback
	
	class AudioPlayback::MPGPlayback < AudioPlayback::PlaybackBase

	#protected

		def on_init
			@song = Linux_Song.new @music_file
		end

		def self.set_volume(value)
			system("amixer cset iface=MIXER,name=\"Master Playback Volume\" #{value} > /dev/null")
		end

		def self.get_current_volume
			res = `amixer cget iface=MIXER,name="Master Playback Volume"`
			vals = /min=(?<minv>\d+).+max=(?<maxv>\d+).+values=(?<curv>\d+).+/m.match(res)
			{min:vals["minv"], max:vals["maxv"], current:vals["curv"]}
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
			system("pidof mpg123 > /dev/null")
		end

	private
		

	end

end