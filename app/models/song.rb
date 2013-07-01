class Song < ActiveRecord::Base
  belongs_to :mixtape
  has_many :likes

  attr_accessible :title, :artist, :album, :track_number, :duration, :file, :cover_art

  validates_presence_of :title, :artist, :file, :track_number

  scope :standout, includes(:mixtape).where(Mixtape.arel_table[:id].not_eq(nil)).includes(:likes)

  def duration
    super || 0
  end
end
