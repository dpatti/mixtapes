class User < ActiveRecord::Base
  attr_accessible :email, :name, :provider, :uid

  has_one :mixtape

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.email = auth["info"]["email"]
    end
  end

  def owns?(mixtape)
    mixtape.user_id == id
  end
end
