require 'digest/md5'

class User < ActiveRecord::Base
  has_one :mixtape
  has_many :comments
  has_many :likes
  has_many :guesses

  def email_hash
    Digest::MD5.hexdigest(email)
  end

  def gravatar
    "https://secure.gravatar.com/avatar/#{ email_hash }?s=60"
  end

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

  def likes?(song)
    likes.any? {|l| l.song_id == song.id}
  end

  def accessed_at
    # Backfill
    super || created_at
  end

  def active?
    if mixtape && !mixtape.songs.empty?
      return true
    end

    return accessed_at > Settings.contest.start
  end
end
