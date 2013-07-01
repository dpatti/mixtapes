require 'taglib'
require 'streamio-ffmpeg'

class Song < ActiveRecord::Base
  belongs_to :mixtape
  has_many :likes

  attr_accessible :title, :artist, :album, :track_number, :duration, :file, :cover_art

  validates_presence_of :title, :artist, :file, :track_number

  scope :standout, includes(:mixtape).where(Mixtape.arel_table[:id].not_eq(nil)).includes(:likes)

  def duration
    super || 0
  end

  def set_metadata(filename, path)
    TagLib.const_get(Song.taglib_type(filename))::File.open(path) do |file|
      tag = file.tag

      return unless tag

      self.title = tag.title || filename
      self.artist = tag.artist || "Unknown"
      self.album = tag.album
    end
  end

  def set_duration(file)
    # Yes, Movie. There is no explicit audio class, but it does exactly what
    # we'd want it to
    self.duration = FFMPEG::Movie.new(file).duration.round
  end

  def self.taglib_type(filename)
    case (filetype = File.extname(filename))
    when '.mp3'
      type = 'MPEG'
    when '.m4a'
      type = 'MP4'
    else
      raise "Invalid file type: #{ filetype }"
    end
  end
end
