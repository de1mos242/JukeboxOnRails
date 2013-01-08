class SongsController < ApplicationController

  include AudioPlayback   
  include AudioProviders
  require 'base_queue'

  # GET /songs
  # GET /songs.json
  def index
    @songs = Song.downloaded

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @songs }
    end
  end

  # GET /songs/1
  # GET /songs/1.json
  def show
    @song = Song.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @song }
    end
  end

  # GET /songs/new
  # GET /songs/new.json
  def new
    @song = Song.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @song }
    end
  end

  # GET /songs/1/edit
  def edit
    @song = Song.find(params[:id])
  end

  # POST /songs
  # POST /songs.json
  def create
    @song = Song.new(params[:song])

    respond_to do |format|
      if @song.save
        format.html { redirect_to @song, notice: 'Song was successfully created.' }
        format.json { render json: @song, status: :created, location: @song }
      else
        format.html { render action: "new" }
        format.json { render json: @song.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /songs/1
  # PUT /songs/1.json
  def update
    @song = Song.find(params[:id])

    respond_to do |format|
      if @song.update_attributes(params[:song])
        format.html { redirect_to @song, notice: 'Song was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @song.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /songs/1
  # DELETE /songs/1.json
  def destroy
    @song = Song.find(params[:id])
    @song.destroy

    respond_to do |format|
      format.html { redirect_to songs_url }
      format.json { head :no_content }
    end
  end

  def play
    @song = Song.find(params[:id])
    player = AudioPlayback::MPGPlayback.new @song.filename
    player.play
    redirect_to @song
  end

  def find
    unless params["find_query"].blank?
      finded_songs = AudioProviders::VKProvider.find_by_query(params["find_query"])[0...30]
      @songs = []
      p "find songs #{finded_songs.collect {|song_data| song_data[:url]}}"
      songs_in_cache = Song.where(url: finded_songs.collect {|song_data| song_data[:url]})
      finded_songs.each do |song_data|
        song = songs_in_cache.select {|s| s.url == song_data[:url]}
        if song.nil?
          song = Song.new(artist:song_data[:artist], title:song_data[:track_name], url:song_data[:url])
        end
        @songs.push(song)
      end
    else
      @songs = Song.downloaded
    end
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @songs }
    end
    
  end

  def download
    @song = Song.find(params[:id])
    @song.download do
      Playlist.refresh
    end
    
    render :nothing => true
  end

  def add_to_playlist
    if Song.exists?(params[:song][:id])
      song = Song.find(params[:song][:id])
    else
      user_song = params[:song]
      song = Song.create(artist:user_song[:artist], title:user_song[:title], url:user_song[:url], duration:user_song[:duration])
    end
    
    MessageQueue::BaseQueue.SendBroadcastMessage("playlist.add.song", {}, song.id)
    #Playlist.add_song(song)
    render :nothing => true
  end
end
