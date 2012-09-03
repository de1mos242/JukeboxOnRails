class ControlPanelController < ApplicationController
  def index
    @playlist_items = PlaylistItem.position_sorted
    @songs = Song.downloaded
    @volumes = AudioPlayback::MPGPlayback.get_current_volume
  end
end
