class Mixtape < ActiveRecord::Base
  has_many :songs
  belongs_to :user

  attr_accessible :name, :cover, :owner

  def duration
    songs.map(&:duration).reduce(:+)
  end

  def ordered_songs
    songs.sort_by(&:track_number)
  end

  def self.create_for(user)
    raise "No user supplied" unless user

    create do |mixtape|
      mixtape.user_id = user.id
    end
  end
end
