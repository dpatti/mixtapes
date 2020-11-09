require 'zip'

class MixtapesController < ApplicationController
  helper_method :contest_context

  # All modifications must be done *before* the due date. That includes any
  # POST, PATCH, or DELETE.

  # Show all mixtapes
  def index
    @contest = Contest.find(params[:contest_id])
    refuse_access and return if @contest.before?

    @mixtapes = @contest.mixtapes.with_songs.each do |mixtape|
      if current_user
        mixtape.with_last_read_time_for(current_user)
      end
    end

    # XXX: I tried doing this using the associations, i.e.,
    # `@contest.comments.latest(10)`. For some reason, part of the default_scope
    # for `Mixtape` was being applied and it was raising because the `songs`
    # table join was referenced but it wasn't... joined. I don't know.
    #
    # I tried later after removing the `with_songs` from the default scope, and
    # the alphabetical ordering scope of the mixtapes interfered with `latest`
    # and gave me the wrong ordering. Everything is bad.
    @comments = Comment.latest(10).where(mixtape: @mixtapes)

    if @contest.daily_mix_day?
      # Build list of mixtapes, randomize and pick one. We concat nil at the end
      # so that when all mixtapes have had a day, we stop showing a current mix.
      seeded_order = @mixtapes.shuffle(random: @contest.rotation_seed).push(nil)
      *@previous, @highlight = seeded_order.take(rotation_day + 1)
      @previous.uniq!
    end
  end

  # Show details about a single mixtape
  def show
    @mixtape = Mixtape.find(params[:id])
    @comment = Comment.new

    if @mixtape.contest.before?
      if has_private_access_to(@mixtape)
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
    if contest_started or !has_private_access_to(@mixtape)
      refuse_access and return
    end
    @mixtape.update_attributes(mixtape_params)
    head :no_content
  end

  # Prompt for deletion
  def destroy_confirm
    @mixtape = Mixtape.find(params[:id])
    if contest_started or !has_private_access_to(@mixtape)
      refuse_access and return
    end
  end

  # DELETE: Remove mixtape
  def destroy
    @mixtape = Mixtape.find(params[:id])
    if contest_started or !has_private_access_to(@mixtape)
      refuse_access and return
    end
    @mixtape.songs.each(&:destroy)
    @mixtape.destroy
    redirect_to root_path
  end

  def download
    @mixtape = Mixtape.find(params[:id])

    if @mixtape.contest.before? && !has_private_access_to(@mixtape)
      refuse_access and return
    end

    @mixtape.cache_or_zip

    send_file @mixtape.cache_path, :filename => @mixtape.filename, :disposition => 'attachment', :type => :zip
  end

  def listen
    consume('listen')
  end

  def visualize
    consume('visualizer')
  end

  def listen_random
    contest = Contest.find(params[:contest_id])
    id = contest.mixtapes.with_songs.map(&:id).sample
    return redirect_to visualize_mixtape_path(id)
  end

  private

  def mixtape_params
    params.require(:mixtape).permit(:name, :cover)
  end

  def consume(template)
    mixtape = Mixtape.includes(:songs).find(params[:id])

    if mixtape.contest.before? && !has_private_access_to(mixtape)
      refuse_access and return
    end

    @title = mixtape.name
    # Do smart detection if it is a compilation so we only create a playlist
    # with that track.
    compilation = mixtape.songs.find(&:compilation)
    @songs = compilation ? [compilation] : mixtape.songs
    render :layout => false, :template => template
  end

  def has_private_access_to(mixtape)
    current_user && current_user.owns?(mixtape)
  end

  def contest_context
    @contest_context ||= begin
      if params[:mixtape_id]
        Mixtape.find(params[:mixtape_id]).contest
      elsif params[:id]
        Mixtape.find(params[:id]).contest
      end
    end || super
  end
end
