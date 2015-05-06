require 'zip'

class Mixtape < ActiveRecord::Base
  has_many :songs, :order => 'track_number, id'
  has_many :comments, :order => 'created_at'
  has_many :last_reads
  belongs_to :user

  default_scope order('name')

  # Only get Mixtapes that have at least one song
  scope :with_songs, lambda { includes(:songs).where('songs.id is not null') }

  def with_last_read_time_for(user)
    last = last_reads.where(:user_id => user.id).first
    @last_read_time = last ? last.time : 0
  end

  def unread_count
    @unread_count ||= comments.after(@last_read_time).count.tap do |n|
      return nil if n <= 0
    end
  end

  def last_unread
    @last_unread ||= comments.after(@last_read_time).first
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
    File.join(Settings.cache_path, "#{ id }.zip")
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
