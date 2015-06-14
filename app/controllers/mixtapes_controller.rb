require 'zip'

class MixtapesController < ApplicationController
  # All modifications must be done *before* the due date. That includes any
  # POST, PATCH, or DELETE.

  # Show all mixtapes
  def index
    refuse_access and return if before_contest

    @mixtapes = Mixtape.with_songs.all.each do |mixtape|
      if current_user
        mixtape.with_last_read_time_for(current_user)
      end
    end

    @comments = Comment.latest

    if daily_mix_day?
      # Build list of mixtapes, randomize and pick one. We concat nil at the end
      # so that when all mixtapes have had a day, we stop showing a current mix.
      seeded_order = Mixtape.with_songs.shuffle(random: rotation_seed).push(nil)
      *@previous, @highlight = seeded_order.take(rotation_day + 1)
      @previous.uniq!
    end
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

    @mixtape = Mixtape.new(mixtape_params)

    if @mixtape.save
      flash[:info] = "Mixtape created successfully"
      session[:mixtape] = @mixtape.id
      redirect_to @mixtape
    else
      render 'new'
    end
  end

  # PATCH: Modify mixtape
  def update
    @mixtape = Mixtape.find(params[:id])
    if contest_started or not current_user.owns? @mixtape
      refuse_access and return
    end
    @mixtape.update_attributes(mixtape_params)
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
      Zip::File.open(cache_path, Zip::File::CREATE) do |zip|
        mixtapes.each do |m|
          m.add_songs(zip)
        end
      end
    end

    send_file cache_path, :filename => "FogCreekTrello2015Mixes.zip", :disposition => 'attachment'
  end

  def listen
    consume('listen')
  end

  def visualize
    consume('visualizer')
  end

  private

  def mixtape_params
    params.require(:mixtape).permit(:name, :cover)
  end

  def consume(template)
    if before_contest
      refuse_access and return
    end

    if params[:id] == "random"
      id = Mixtape.with_songs.map(&:id).sample
      return redirect_to listen_mixtape_path(id)
    end

    mixtape = Mixtape.includes(:songs).find(params[:id])
    @title = mixtape.name
    # Do smart detection if it is a compilation so we only create a playlist
    # with that track.
    compilation = mixtape.songs.find(&:compilation)
    @songs = compilation ? [compilation] : mixtape.songs
    render :layout => false, :template => template
  end
end
