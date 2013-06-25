class MixtapesController < ApplicationController
  # All modifications must be done *before* the due date. That includes any
  # POST, PUT, or DELETE.

  # Show all mixtapes
  def index
    refuse_access and return if during_contest

    @mixtapes = Mixtape.all
  end

  # Show details about a single mixtape
  def show
    @mixtape = Mixtape.find(params[:id])
    @owner = current_user.owns? @mixtape

    if pre_contest
      refuse_access and return unless @owner
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
    refuse_access and return if during_contest

    @mixtape = Mixtape.new(params[:mixtape])

    if @mixtape.save
      flash[:info] = "Mixtape created successfully"
      session[:mixtape] = @mixtape.id
      redirect_to @mixtape
    else
      render 'new'
    end
  end

  # Unused: Edit form will be on the show(?)
  def edit
    refuse_access
  end

  # PUT: Modify mixtape
  def update
    refuse_access and return if during_contest
    @mixtape = Mixtape.find(params[:id])
    @mixtape.require_password or return
  end

  # DELETE: Remove mixtape
  def destroy
    refuse_access and return if during_contest
    @mixtape = Mixtape.find(params[:id])
    @mixtape.require_password or return
  end
end
