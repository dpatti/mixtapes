require 'taglib'
require 'streamio-ffmpeg'
# Lib
require 'string_similarity'
require 'song_db'

class Song < ActiveRecord::Base
  belongs_to :mixtape, :touch => true
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

  def filename
    File.join(mixtape.name, ("%02d - %s - %s.%s" % [track, artist, title, extension]).gsub('/', ''))
  end

  def file
    File.join(Settings.upload_path, mixtape.user_id.to_s, super)
  end

  def track
    mixtape.songs.index(self) + 1
  end

  def extension
    return @extension if @extension

    # I forgot to save this anywhere. Ugh. TEMP FIX

    ["a.m4a", "b.mp3"].find do |type|
      Song.taglib_type(type)::File.open(file) do |file|
        if file.audio_properties != nil
          return @extension = File.extname(type).slice(1..-1)
        end
      end
    end
  end

  def similar_to(song)
    opts = { :pre_clean => true, :similarity_thresh => 90 }
    title.similar_to(song.title, opts) || artist.similar_to(song.artist, opts)
  end

  def similar_songs
    # Get details of other songs
    SongDB.all.select {|song| song.mixtape != mixtape && similar_to(song)}
  end

  def warning
    @warning ||= similar_songs.map do |song|
      '"%s" by %s on %smixtape "%s"' % [
        song.title, song.artist,
        song.new_record? ? 'previous ' : 'current ',
        song.mixtape.name
      ]
    end
  end

  def set_metadata(filename, path)
    Song.taglib_type(filename)::File.open(path) do |file|
      tag = file.tag

      return unless tag

      self.title = tag.title || filename
      self.artist = tag.artist || "Unknown"
      self.album = tag.album
      self.duration = file.audio_properties.length
    end
  end

  def set_duration(file)
    # Yes, Movie. There is no explicit audio class, but it does exactly what
    # we'd want it to
    self.duration ||= FFMPEG::Movie.new(file).duration.round
  end

  def tag_file
    Song.taglib_type(filename)::File.open(file) do |file|
      tag = file.tag

      tag.title = title
      tag.artist = artist
      tag.album = mixtape.name
      tag.track = track

      file.save
    end
  end

  def self.taglib_type(filename)
    case (filetype = File.extname(filename))
    when '.mp3'
      TagLib::MPEG
    when '.m4a'
      TagLib::MP4
    else
      raise "Invalid file type: #{ filetype }"
    end
  end
end
