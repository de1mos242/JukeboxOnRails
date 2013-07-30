class Room < ActiveRecord::Base
<<<<<<< HEAD
  #attr_accessible :name, :users, :user_ids
=======
  attr_accessible :name, :users, :user_ids
>>>>>>> bbcbe771fecc123c9af07129281938150483f288

  has_many :users, through: :room_memberships
  has_many :room_memberships

<<<<<<< HEAD
  scope 

  scope :user_allowed, -> (user) begin
  	if user

  	else

  end

=======
>>>>>>> bbcbe771fecc123c9af07129281938150483f288
end
