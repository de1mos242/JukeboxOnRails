require "open-uri"

class Song < ActiveRecord::Base
  attr_accessible :artist, :filename, :title, :url

  validate :artist, presents:true
  validate :title, presents:true
  validate :url, presents:true

  scope :downloaded, conditions: "filename is not null"
  scope :in_playlist, joins().where("songs.filename is not null")
  
  def downloaded?
  	not self.filename.blank?
  end

  def in_playlist?
    return true unless PlaylistItem.with_song(self).first.nil?
    return false if Playlist.current_song.nil?
    Playlist.current_song.id == self.id
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
		Thread.exit
      end

    rescue NotImplementedError
      raise "*** fork()...exec() not supported ***"
    end
  end
end
