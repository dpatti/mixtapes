require 'zip'

class Mixtape < ActiveRecord::Base
  has_many :songs, -> { order('track_number, id') }
  has_many :comments, -> { order('created_at') }
  has_many :last_reads
  has_many :guesses
  has_many :votes
  belongs_to :contest
  belongs_to :user

  # Only get Mixtapes that have at least one song
  # XXX: I tried to put `with_songs` in the default scope and it broke a lot of
  # association queries because songs was referenced in the where clause but
  # never joined
  scope :with_songs, -> {
    includes(:songs).where('songs.id is not null').references(:songs)
  }

  def with_last_read_time_for(user)
    last = last_reads.where(:user_id => user.id).first
    @last_read_time = last ? last.time : user.created_at
  end

  def unread_count
    # XXX: Simply disabling unread counts since commenting is globally disabled
    if true
      nil
    else
      @unread_count ||= comments.after(@last_read_time).count.tap do |n|
        return nil if n <= 0
      end
    end
  end

  def last_unread
    @last_unread ||= comments.after(@last_read_time).first
  end

  def can_comment?
    # XXX: Simply disabling commenting for now, but if we had another contest we
    # could do something smarter.
    false
  end

  def name
    super || "Untitled Mix"
  end

  def creator
    user.name
  end

  def duration
    songs.map(&:duration).reduce(:+) || 0
  end

  def voteable_by?(user)
    user && user.id != user_id
  end

  def warning
    case duration
    when 0..40*60
      nil
    when 40*60..45*60
      "Getting a bit long there! Our limit on mixes is 40 minutes. Though you won't be instantly disqualified, the added minutes better be damn worth it!"
    else
      "Holy moly this mix is long. You should probably cut it down a bit! We only want 40 minutes."
    end
  end

  def filename
    "#{ name }.zip"
  end

  def cache_or_zip
    cache = File.stat(cache_path) rescue nil

    if !cache || cache.mtime < updated_at || cache.size < 100
      File.delete(cache_path) rescue nil
      prepare_zip
    end
  end

  def cache_path
    File.join(Settings.cache_path, "mixtape.#{ id }.zip")
  end

  def prepare_zip
    Zip::File.open(cache_path, Zip::File::CREATE) do |zip|
      add_songs(zip)
    end
  end

  def add_songs(zip)
    songs.each do |song|
      song.tag_file
      zip.add(song.filename, song.file)
    end
  end

  def self.create_for(user)
    raise "No user supplied" unless user

    create do |mixtape|
      mixtape.user_id = user.id
    end
  end
end
