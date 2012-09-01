class SongsController < ApplicationController

  include AudioPlayback   
  include AudioProviders

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

  def stop
    Playlist.stop
    render :nothing => true
  end

  def find
    finded_songs = AudioProviders::VKProvider.find_by_query(params["find_query"])
    @finded_songs = []
    finded_songs.each do |song_data|
      song = Song.find_by_url(song_data[:url])
      if song.nil?
        song = Song.create(artist:song_data[:artist], title:song_data[:track_name], url:song_data[:url])
      end
      @finded_songs.push(song)
    end
    @songs = Song.downloaded
    render :index
  end

  def download
    @song = Song.find(params[:id])
    @song.download do
      Playlist.refresh
    end
    
    render :nothing => true
  end

  def add_to_playlist
    song = Song.find(params[:id])
    Playlist.add_song(song)
    
    render :nothing => true
  end
end
