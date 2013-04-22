class RoomMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :room
  # attr_accessible :title, :body
end
