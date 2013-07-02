require 'taglib'
require 'streamio-ffmpeg'
# Lib
require 'string_similarity'
require 'song_db'

class Song < ActiveRecord::Base
  ALBUM_ARTIST = "Fog Creek Mixes"

  belongs_to :mixtape, :touch => true
  has_many :likes

  attr_accessible :title, :artist, :album, :track_number, :duration, :file, :cover_art

  validates_presence_of :title, :artist, :file, :track_number

  scope :on_mixtape, includes(:mixtape).where(Mixtape.arel_table[:id].not_eq(nil))
  scope :standout, on_mixtape.includes(:likes)

  def on_mixtapes_other_than(mixtape_id)
    where('mixtape_id != ?', mixtape_id)
  end

  def hearts
    (likes.count / 5).to_i
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
      tag.year = 2013

      # Okay, do the stupid "Album Artist" so that all media players feel included
      if file.respond_to? :id3v2_tag
        id3v2_tag = file.id3v2_tag

        %w{TPE2 TSOP TSO2}.each do |frame_id|
          # Remove all
          id3v2_tag.remove_frames(frame_id)

          # Re-add it
          TagLib::ID3v2::TextIdentificationFrame.new(frame_id, TagLib::String::UTF8).tap do |frame|
            frame.text = ALBUM_ARTIST
            id3v2_tag.add_frame(frame)
          end
        end

        # Remove TPOS -- disc number
        id3v2_tag.remove_frames('TPOS')
      else
        puts "#{ filename } has mp4 tag"
        item_list_map = tag.item_list_map
        %w{aART soaa soar}.each do |frame_id|
          item_list_map.erase(frame_id)
          item_list_map.insert(frame_id, TagLib::MP4::Item.from_string_list([ALBUM_ARTIST]))
        end

        # Remove disk -- disc number
        item_list_map.erase('disk')
      end

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
