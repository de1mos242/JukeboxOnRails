class ControlPanelController < ApplicationController
  def index
    @songs = Song.downloaded
    
    @playlist_items = PlaylistItem.position_sorted.in_queue
    @volumes = AudioPlayback::MPGPlayback.get_current_volume

    respond_to do |format|
      format.html { render :index }
    end
  end

  def refresh
    @playlist_items = PlaylistItem.position_sorted
    @volumes = AudioPlayback::MPGPlayback.get_current_volume
    @current_song = Playlist.current_song
    respond_to do |format|
      format.json { render :refresh }
    end
  end

  def find
    unless params["find_query"].blank?
      finded_songs = AudioProviders::VKProvider.find_by_query(params["find_query"])[0...30]
      @songs = []
      finded_songs.each do |song_data|
        song = Song.with_url(song_data[:url]).first
        if song.nil?
          song = Song.new(artist:song_data[:artist], title:song_data[:track_name], url:song_data[:url])
        end
        @songs.push(song)
      end
    else
      @songs = Song.downloaded
    end

    respond_to do |format|
      format.json { render json: @songs }
    end
  end
end
