class Song < ActiveRecord::Base
  belongs_to :mixtape

  attr_accessible :title, :artist, :album, :track_number, :duration, :file, :cover_art

  validates_presence_of :title, :artist, :file, :track_number
end
