require "open-uri"

class Song < ActiveRecord::Base
  attr_accessible :artist, :filename, :title, :url

  scope :downloaded, conditions: "filename is not null"
  

  def download
  	begin
  	  download_path = Rails.application.config.songs_path
  	  short_filename = /\/(?<short_name>[^\/]+?)$/.match(self.url)["short_name"]
  	  filename = download_path.join(short_filename)
  	  url = self.url
  	  song_id = self.id
  	  puts "\n\n\nstart"
      pid = fork do
      	puts "\n\n\nfork"
        open(filename, 'wb') do |dst|
		  open(url) do |src|
		    dst.write(src.read)
		  end
		end
		puts "\n\n\ndownloaded"
		song = Song.find(song_id)
		song.filename = filename.to_s
		song.save
		puts "\n\n\nsaved"
      end

      Process.detach(pid)
    rescue NotImplementedError
      raise "*** fork()...exec() not supported ***"
    end
  end
end
