require 'taglib'
require 'streamio-ffmpeg'
# Lib
require 'string_similarity'
require 'song_db'

class Song < ActiveRecord::Base
  belongs_to :mixtape
  has_many :likes

  attr_accessible :title, :artist, :album, :track_number, :duration, :file, :cover_art

  validates_presence_of :title, :artist, :file, :track_number

  scope :on_mixtape, includes(:mixtape).where(Mixtape.arel_table[:id].not_eq(nil))
  scope :standout, on_mixtape.includes(:likes)

  def on_mixtapes_other_than(mixtape_id)
    where('mixtape_id != ?', mixtape_id)
  end

  def duration
    super || 0
  end

  def similar_to(song)
    opts = { :pre_clean => true, :similarity_thresh => 90 }
    title.similar_to(song.title, opts) && artist.similar_to(song.artist, opts)
  end

  def similar_songs
    # Get details of other songs
    SongDB.all.select {|song| song.mixtape != mixtape && similar_to(song)}
  end

  def warning
    similar_songs.map do |song|
      '"%s" by %s on %smixtape "%s"' % [
        song.title, song.artist,
        song.new_record? ? 'previous ' : 'current ',
        song.mixtape.name
      ]
    end
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
