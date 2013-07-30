class User < ActiveRecord::Base

  ROOM_ADMIN_ROLE = 'room_admin'
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :nickname, :url, :username, :token, :expiration_date

  has_many :rooms, through: :room_memberships
  has_many :room_memberships

  def vk_expired?
    Time.now >= expiration_date
  end

  has_many :rooms, through: :room_memberships
  has_many :room_memberships

  def self.find_for_vkontakte_oauth access_token
    user = User.where(:url => access_token.info.urls.Vkontakte).first
    p access_token.inspect
    unless user.nil?
      user.token = access_token.credentials.token
      user.expiration_date = Time.at(access_token.credentials.expires_at)
      user.save!
      user
    else
      user = User.create!(url: access_token.info.urls.Vkontakte,
                   :username => access_token.info.name,
                   :nickname => access_token.info.nickname,
                   :email => access_token.uid.to_s+'@vk.com',
                   :token => access_token.credentials.token,
                   :password => Devise.friendly_token[0,20],
                   expiration_date: Time.at(access_token.credentials.expires_at) )
    end
    has_admin = User.where(:roles, ROOM_ADMIN_ROLE).count > 0
    unless has_admin
      user.roles = ROOM_ADMIN_ROLE
      user.save!
    end
    user
  end

  def room_admin?
    roles == ROOM_ADMIN_ROLE
  end
end
