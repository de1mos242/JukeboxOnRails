require "open-uri"

class Song < ActiveRecord::Base
  attr_accessible :artist, :filename, :title, :url

  scope :downloaded, conditions: "filename is not null"
  
  def downloaded?
  	not self.filename.blank?
  end

  def download
  	begin
  	  download_path = Rails.application.config.songs_path
  	  short_filename = /\/(?<short_name>[^\/]+?)$/.match(self.url)["short_name"]
  	  filename = download_path.join(short_filename)
  	  url = self.url
  	  song_id = self.id
  	  puts "\n\n\nstart"
  	  puts "block: #{block_given?}"
      Thread.new do
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
		puts "block: #{block_given?}"
		if block_given?
			yield
		end

      end

    rescue NotImplementedError
      raise "*** fork()...exec() not supported ***"
    end
  end
end
