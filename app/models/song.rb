require "open-uri"
require 'yaml'

class Song < ActiveRecord::Base
  #attr_accessible :artist, :filename, :title, :url, :song_hash, :duration, :room
  before_create :fill_song_hash

  validate :artist, presents:true
  validate :title, presents:true
  validate :url, presents:true
  validate :song_hash, presents:true

  belongs_to :room

  scope :downloaded, -> { where("filename is not null") }
  #scope :in_playlist, -> {joins("songs").where("songs.filename is not null")}
  scope :with_url, -> (url) { where(song_hash: url.gsub(/^.+\//, '') ) }
  scope :in_room, -> (room_id) { where(room: room_id) }
  
  def downloaded?
  	not self.filename.blank?
  end

  def in_playlist?
    return true unless PlaylistItem.with_song(self).first.nil?
    return false if Playlist.current_song.nil?
    Playlist.current_song.id == self.id
  end

  def fill_song_hash
    p "url: #{url} and self.url: #{self.url}"
    self.song_hash = self.url.gsub(/^.+\//, '') 
  end

  def download
    rails_root = File.expand_path('../../..', __FILE__)
    env = ENV['RACK_ENV'] || 'development'
    config = YAML.load(File.read(File.join(rails_root, "config", 'audio', "common.yml")))[env]
	  download_path = config[:songs_path]
	  short_filename = /\/(?<short_name>[^\/]+?)$/.match(self.url)["short_name"]
	  filename = File.join(download_path, short_filename)
	  url = self.url
	  song_id = self.id
	  puts "download started"
  	open(filename, 'wb') do |dst|
		  open(url) do |src|
		    dst.write(src.read)
		  end
		end
    puts "#{artist} - #{title} #{filename} downloaded"
    filename
  end
end
