require 'taglib'

class SongsController < ApplicationController
  def index
    refuse_access
  end

  def create
    @mixtape = Mixtape.find(params[:mixtape_id])
    if during_contest or not current_user.owns? @mixtape
      refuse_access and return 
    end

    song = TagLib::MPEG::File.open(params[:song_file].tempfile.path) do |file|
      tag = file.id3v2_tag

      { :title => tag.title,
        :artist => tag.artist }
    end

    song = @mixtape.songs.new(song)

    if song.save
      flash[:info] = "Uploaded #{ song[:title] } by #{ song[:artist] }"
      head :no_content
    else
      flash[:error] = "Could not detect properties of #{ params[:song_file].original_filename }"
      head :bad_request
    end
  end

  def update
    @song = Song.find(params[:mixtape_id])
    if during_contents or not current_user.owns? @song.mixtape
      refuse_access and return
    end

    @song.update_attributes(params[:song])
  end

  def destroy
    @song = Song.find(params[:mixtape_id])
    if during_contents or not current_user.owns? @song.mixtape
      refuse_access and return
    end

    @song.destroy
  end
end
