class ControlPanelController < ApplicationController
  def index
    @songs = Song.downloaded
    p "#{Rails.application.config.common_audio_config}"
    @long_poll_server = Rails.application.config.common_audio_config[:long_poll_server]
    @playlist_items = PlaylistItem.position_sorted.in_queue
    @volumes = AudioPlayback::GStreamPlayback.get_current_volume
    @shoutcast_url = AudioPlayback::GStreamPlayback.get_shoutcast_url
    puts "shoutcast_url= #{@shoutcast_url}"
    puts "shoutcast_url.nil?= #{@shoutcast_url.nil?}"
    puts "shoutcast_url.blank?= #{@shoutcast_url.blank?}"

    respond_to do |format|
      format.html { render :index }
    end
  end

  def refresh
    @playlist_items = PlaylistItem.position_sorted.in_queue
    @volumes = AudioPlayback::GStreamPlayback.get_current_volume
    @current_song = Playlist.current_song
    @current_position = AudioPlayback::GStreamPlayback.get_position
    respond_to do |format|
      format.json { render :refresh }
    end
  end

  def find
    unless params["find_query"].blank?
      found_songs = AudioProviders::VKProvider.find_by_query(params["find_query"])[0...30]
      @songs = []
      p "find songs #{found_songs.collect {|song_data| song_data[:url]}}"
      songs_in_cache = Song.where(url: found_songs.collect {|song_data| song_data[:url]})
      found_songs.each do |song_data|
        cached_song = songs_in_cache.select {|s| s.url == song_data[:url]}
        song = nil
        song = cached_song[0] if cached_song.size > 0
        song = Song.new(artist: song_data[:artist], title: song_data[:track_name], url: song_data[:url], duration: song_data[:duration]) if song.nil?
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
