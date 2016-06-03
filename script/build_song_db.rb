require 'taglib'
require 'yaml'

def taglib_type(filename)
  case (filetype = File.extname(filename))
  when '.mp3'
    TagLib::MPEG
  when '.m4a'
    TagLib::MP4
  else
    raise "Invalid file type: #{ filetype }"
  end
end

mixtapes = {}
p File.join(ARGV.first || ".", "**", "*")
Dir[File.join(ARGV.first || ".", "**", "*")].each do |f|
  begin
    taglib_type(f)::File.open(f) do |file|
      tag = file.tag
      mixtape = File.basename(File.dirname(f))

      mixtapes[mixtape] ||= []
      mixtapes[mixtape] << { :title => tag.title, :artist => tag.artist }
    end

  # Because the file filter also gets folders, which aren't music files
  rescue
      # Who knows how to rescue this mess of patchwork code
  end
end

File.open("song_db.yml", "w") do |file|
  file.write(mixtapes.to_yaml)
end
