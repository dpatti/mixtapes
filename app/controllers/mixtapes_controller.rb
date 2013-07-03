require 'zip/zip'

class MixtapesController < ApplicationController
  # All modifications must be done *before* the due date. That includes any
  # POST, PUT, or DELETE.

  # Show all mixtapes
  def index
    refuse_access and return if before_contest

    @mixtapes = Mixtape.with_songs.all.each do |mixtape|
      if current_user
        mixtape.with_last_read_time_for(current_user)
      end
    end

    @comments = Comment.latest
  end

  # Show details about a single mixtape
  def show
    @mixtape = Mixtape.includes(:comments).find(params[:id])
    @comment = Comment.new

    if before_contest
      if current_user && current_user.owns?(@mixtape)
        render 'edit'
      else
        refuse_access and return
      end
    end

    # Update last read
    if current_user
      LastRead.update_pair(current_user.id, @mixtape.id)
    end
  end

  # Unused: Show the form to create a new mixtape
  def new
    # Debug: just do the create for now
    redirect_to Mixtape.create_for(current_user)

    # refuse_access
  end

  # POST: Create the actual mixtape
  def create
    refuse_access and return if contest_started

    @mixtape = Mixtape.new(params[:mixtape])

    if @mixtape.save
      flash[:info] = "Mixtape created successfully"
      session[:mixtape] = @mixtape.id
      redirect_to @mixtape
    else
      render 'new'
    end
  end

  # PUT: Modify mixtape
  def update
    @mixtape = Mixtape.find(params[:id])
    if contest_started or not current_user.owns? @mixtape
      refuse_access and return
    end
    @mixtape.update_attributes(params[:mixtape])
    head :no_content
  end

  # Prompt for deletion
  def destroy_confirm
    @mixtape = Mixtape.find(params[:id])
    if contest_started or not current_user.owns? @mixtape
      refuse_access and return
    end
  end

  # DELETE: Remove mixtape
  def destroy
    @mixtape = Mixtape.find(params[:id])
    if contest_started or not current_user.owns? @mixtape
      refuse_access and return
    end
    @mixtape.songs.each(&:destroy)
    @mixtape.destroy
    redirect_to root_path
  end

  def download
    @mixtape = Mixtape.find(params[:id])

    if before_contest && (!current_user || !current_user.owns?(@mixtape))
      refuse_access and return
    end

    @mixtape.cache_or_zip

    send_file @mixtape.cache_path, :filename => @mixtape.filename, :disposition => 'attachment'
  end

  def download_all
    mixtapes = Mixtape.with_songs
    cache_path = File.join(Settings.cache_path, "all.zip")
    cache = File.stat(cache_path) rescue nil

    if !cache || cache.mtime < mixtapes.map(&:updated_at).max || cache.size < 100
      File.delete(cache_path) rescue nil
      Zip::ZipFile.open(cache_path, Zip::ZipFile::CREATE) do |zip|
        mixtapes.each do |m|
          m.add_songs(zip)
        end
      end
    end

    send_file cache_path, :filename => "FogCreek2013Mixes.zip", :disposition => 'attachment'
  end

  def listen
    render :text => "Not yet implemented"
  end
end
