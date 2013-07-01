require 'taglib'

mixtapes = {}
p File.join(ARGV.first || ".", "**", "*")
Dir[File.join(ARGV.first || ".", "**", "*")].each do |f|
  song = Song.new {|s| s.set_metadata(f, f)} rescue next
  mixtape = File.basename(File.dirname(f))

  mixtapes[mixtape] ||= []
  mixtapes[mixtape] << { :title => song.title, :artist => song.artist }
end

File.open("song_db.yml", "w") do |file|
  file.write(mixtapes.to_yaml)
end
