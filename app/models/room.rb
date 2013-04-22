class Room < ActiveRecord::Base
  attr_accessible :name, :users, :user_ids

  has_many :users, through: :room_memberships
  has_many :room_memberships

end
