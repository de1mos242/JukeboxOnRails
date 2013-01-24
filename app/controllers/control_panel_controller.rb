class ControlPanelController < ApplicationController
  def index
    #@songs = Song.downloaded
    @long_poll_server = Rails.application.config.common_audio_config[:long_poll_server]
    @playlist_items = PlaylistItem.position_sorted.in_queue
    @volumes = AudioPlayback::GStreamPlayback.get_current_volume
    @shoutcast_url = AudioPlayback::GStreamPlayback.get_shoutcast_url
    puts "shoutcast_url= #{@shoutcast_url}"
    
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
    if !params["find_query"].blank? && user_signed_in?
      #found_songs = AudioProviders::VKProvider.find_by_query(params["find_query"])[0...30]
      vk = VkontakteApi::Client.new current_user.token
      vk_songs = vk.audio.search(q: params["find_query"], auto_complete:1, count:30)
      found_songs = vk_songs[1..30].collect do |vk_song|
        { artist: vk_song.artist,
          track_name: vk_song.title,
          url: vk_song.url,
          duration: sprintf("%02d:%02d", vk_song.duration/60, vk_song.duration%60)
        }
      end
      @songs = []
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
