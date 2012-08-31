class PlaylistItem < ActiveRecord::Base
  belongs_to :song
  attr_accessible :position
end
