class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :nickname, :url, :username, :token

  def self.find_for_vkontakte_oauth access_token
    user = User.where(:url => access_token.info.urls.Vkontakte).first
    p access_token.inspect
    unless user.nil?
      user
    else
      User.create!(url: access_token.info.urls.Vkontakte,
                   :username => access_token.info.name,
                   :nickname => access_token.info.nickname,
                   :email => access_token.uid.to_s+'@vk.com',
                   :token => access_token.credentials.token,
                   :password => Devise.friendly_token[0,20])
    end
  end
end
