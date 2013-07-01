class SongDB
  def self.all
    current + history
  end

  def self.current
    Song.all
  end

  def self.history
    YAML::load_file('config/song_db.yml').map do |mixtape, songs|
      mixtape = Mixtape.new(:name => mixtape)

      songs.map do |song|
        Song.new(song) {|s| s.mixtape = mixtape}
      end
    end.flatten
  end
end
