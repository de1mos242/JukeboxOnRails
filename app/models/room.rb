class Room < ActiveRecord::Base
  #attr_accessible :name, :users, :user_ids

  has_many :users, through: :room_memberships
  has_many :room_memberships

  scope 

  scope :user_allowed, -> (user) begin
  	if user

  	else

  end

end
