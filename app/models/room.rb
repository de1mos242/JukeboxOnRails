class Room < ActiveRecord::Base
  #attr_accessible :name, :users, :user_ids

  has_many :users, through: :room_memberships
  has_many :room_memberships

  has_many :songs

  def get_main_room
  	room = self.find(main_room:true)
  end

end
