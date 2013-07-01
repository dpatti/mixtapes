class Mixtape < ActiveRecord::Base
  has_many :songs, :order => 'track_number, id'
  has_many :comments, :order => 'created_at'
  belongs_to :user

  attr_accessible :name, :cover

  # Only get Mixtapes that have at least one song
  scope :with_songs, includes(:songs).where('songs.id is not null')

  def name
    super || "Untitled Mix"
  end

  def creator
    "anonymous" # user.name
  end

  def duration
    songs.map(&:duration).reduce(:+) || 0
  end

  def self.create_for(user)
    raise "No user supplied" unless user

    create do |mixtape|
      mixtape.user_id = user.id
    end
  end
end
