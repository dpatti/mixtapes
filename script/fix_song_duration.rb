Song.all.each do |song|
  # If it doesn't have a mixtape, skip since #filename() will fail
  next if song.mixtape.nil?

  Song.taglib_type(song.filename)::File.open(song.file) do |file|
    tag = file.tag

    if song.duration.nil? or song.duration == 0
      song.update_column('duration', file.audio_properties.length)
      puts "Updated duration of #{ song.title } to #{ file.audio_properties.length }"
    end
  end
end
