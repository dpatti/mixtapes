require 'gravatar'

class User < ActiveRecord::Base
  has_many :mixtapes
  has_many :comments
  has_many :likes
  has_many :guesses
  has_many :votes

  def gravatar
    Gravatar.new(email).url
  end

  def self.new_from_omniauth(auth)
    new do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.email = auth["info"]["email"]
    end
  end

  def owns?(mixtape)
    mixtape.user_id == id
  end

  def mixtape_for(contest)
    Mixtape.where(user_id: id, contest_id: contest.id).first
  end

  def likes?(song)
    likes.any? {|l| l.song_id == song.id}
  end

  def accessed_at
    # Backfill
    super || created_at
  end

  def active?
    if mixtapes.any? {|mixtape| !mixtape.songs.empty? }
      return true
    end

    return accessed_at > Settings.contest.start
  end
end
