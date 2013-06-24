class Mixtape < ActiveRecord::Base
  has_many :songs

  attr_accessible :name, :cover, :owner, :password

  validates :password, :presence => true,
                       :length => { :minimum => 1 }

  def duration
    @songs.map(&:duration).reduce(:+)
  end

  def require_password

  end
end
