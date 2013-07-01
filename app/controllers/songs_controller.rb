require 'taglib'
require 'fileutils'

class SongsController < ApplicationController
  def create
    @mixtape = Mixtape.find(params[:mixtape_id])
    if contest_started or not current_user.owns? @mixtape
      refuse_access and return 
    end

    case (filetype = params[:song_file].original_filename.split('.').last)
    when 'mp3'
      type = 'MPEG'
    when 'm4a'
      type = 'MP4'
    else
      render :text => "Invalid file type: #{ filetype }", :status => :bad_request and return
    end

    song = TagLib.const_get(type)::File.open(params[:song_file].tempfile.path) do |file|
      tag = file.tag

      next unless tag

      { :title => tag.title || params[:song_file].original_filename,
        :artist => tag.artist || "Unknown",
        :album => tag.album }
    end

    # Find max song
    song[:track_number] = (@mixtape.songs.map(&:track_number).max || 0) + 1

    # New name - 16 random characters
    song[:file] = rand(36**16).to_s(36)

    # Make directory for person
    target_path = File.join(Settings.upload_path, current_user.id.to_s)
    FileUtils.mkdir_p(target_path)

    # Copy file to upload directory
    FileUtils.mv(params[:song_file].tempfile, File.join(target_path, song[:file]))

    # Create actual song record
    song = @mixtape.songs.new(song)

    if song.save
      render :json => song
    else
      flash[:error] = [flash[:error]].flatten.compact
      flash[:error] << "Could not detect properties of #{ params[:song_file].original_filename }"
      head :bad_request
    end
  end

  def update
    @song = Song.find(params[:id])
    if contest_started or not current_user.owns? @song.mixtape
      refuse_access and return
    end

    @song.update_attributes(params[:song])
    head :no_content
  end

  def destroy
    @song = Song.find(params[:id])
    if contest_started or not current_user.owns? @song.mixtape
      refuse_access and return
    end

    @song.destroy
    head :no_content
  end
end
