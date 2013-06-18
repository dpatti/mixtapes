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
    @mixtape.require_password or return if pre_contest
  end

  # Show the form to create a new mixtape
  def new
    refuse_access and return if during_contest

    @mixtape = Mixtape.new

    render 'edit'
  end

  # POST: Create the actual mixtape
  def create
    refuse_access and return if during_contest

    @mixtape = Mixtape.new(params[:id])

    if @mixtape.save
      redirect_to @mixtape
    end
  end

  # Unused: Edit form will be on the show(?)
  def edit
    @mixtape = Mixtape.find(params[:id])
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
