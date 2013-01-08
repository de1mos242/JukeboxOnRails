class PlaylistItemsController < ApplicationController
  include AudioPlayback 
  require 'base_queue'

  # GET /playlist_items
  # GET /playlist_items.json
  def index
    @playlist_items = PlaylistItem.position_sorted
    @volumes = AudioPlayback::GStreamPlayback.get_current_volume

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @playlist_items }
    end
  end

  # GET /playlist_items/1
  # GET /playlist_items/1.json
  def show
    @playlist_item = PlaylistItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @playlist_item }
    end
  end

  # GET /playlist_items/new
  # GET /playlist_items/new.json
  def new
    @playlist_item = PlaylistItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @playlist_item }
    end
  end

  # GET /playlist_items/1/edit
  def edit
    @playlist_item = PlaylistItem.find(params[:id])
  end

  # POST /playlist_items
  # POST /playlist_items.json
  def create
    @playlist_item = PlaylistItem.new(params[:playlist_item])

    respond_to do |format|
      if @playlist_item.save
        format.html { redirect_to @playlist_item, notice: 'Playlist item was successfully created.' }
        format.json { render json: @playlist_item, status: :created, location: @playlist_item }
      else
        format.html { render action: "new" }
        format.json { render json: @playlist_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /playlist_items/1
  # PUT /playlist_items/1.json
  def update
    @playlist_item = PlaylistItem.find(params[:id])

    respond_to do |format|
      if @playlist_item.update_attributes(params[:playlist_item])
        format.html { redirect_to @playlist_item, notice: 'Playlist item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @playlist_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /playlist_items/1
  # DELETE /playlist_items/1.json
  def destroy
    @playlist_item = PlaylistItem.find(params[:id])
    @playlist_item.destroy

    respond_to do |format|
      format.html { redirect_to playlist_items_url }
      format.json { head :no_content }
    end
  end

  def stop
    MessageQueue::BaseQueue.SendBroadcastMessage("playlist.stop",{},"stop please") if params.has_key?(:force)
    render :nothing => true
  end

  def skip
    item = PlaylistItem.find_by_position(0)
    if item
      item.add_skip_wish(session[:session_id])
      if item.skipped?
        p "send skip message"
        MessageQueue::BaseQueue.SendBroadcastMessage("playlist.skip",{},"skip please") 
      end
    end
    render :nothing => true
  end

  def change_volume
    #AudioPlayback::GStreamPlayback.set_volume(params["volume"].to_i)

    render :nothing => true
  end

  def now_playing
    @current_song = Playlist.current_song
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end
end
