class Mixtape < ActiveRecord::Base
  has_many :songs
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

  def ordered_songs
    # If for some reason we have items with the same track number (which is
    # really just a positioning integer used for ordering), break the tie with
    # the id. This way what you see in the edit panel is always what you will
    # get on the real thing.
    songs.sort_by {|song| [song.track_number, song.id]}
  end

  def self.create_for(user)
    raise "No user supplied" unless user

    create do |mixtape|
      mixtape.user_id = user.id
    end
  end
end
