require 'fileutils'

class SongsController < ApplicationController
  def index
    @songs = Song.standout
  end

  def create
    @mixtape = Mixtape.find(params[:mixtape_id])
    if contest_started or not current_user.owns? @mixtape
      refuse_access and return 
    end

    # Create actual song record
    song = @mixtape.songs.new do |s|
      s.set_metadata(params[:song_file].original_filename, params[:song_file].tempfile.path)

      # Find duration
      s.set_duration(params[:song_file].tempfile.path)

      # Find max song
      s.track_number = (@mixtape.songs.map(&:track_number).max || 0) + 1

      # New name - 16 random characters
      s.file = rand(36**16).to_s(36)
    end

    # Make directory for person
    target_path = File.join(Settings.upload_path, current_user.id.to_s)
    FileUtils.mkdir_p(target_path)

    # Copy file to upload directory
    FileUtils.mv(params[:song_file].tempfile, File.join(target_path, song.file))

    if song.save
      render :json => { :song => song, :mixtape => @mixtape }, :methods => [:duration, :warning]
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
    render :json => @song.mixtape, :methods => [:duration, :warning]
  end

  def like
    if params[:value]
      # This might fail because of uniqueness, but that's okay
      Like.create do |like|
        like.user_id = current_user.id
        like.song_id = params[:id]
      end
    else
      Like.destroy_all(:user_id => current_user.id, :song_id => params[:id])
    end
    head :no_content
  end
end
