class UsersController < ApplicationController
  before_filter :cookie_params, only: [:new, :create]

  def new
    @user = User.new_from_omniauth(@params)
  end

  def create
    user = User.new_from_omniauth(@params)
    user.save!
    cookies.delete(:auth)
    log_in(user)
  end

  def mixtapes
    refuse_access and return unless current_user

    @mixtapes = current_user.mixtapes.with_songs

    render 'mixtapes/mine'
  end

  def favorites
    refuse_access and return unless current_user

    @title = "My Favorites"
    @songs = current_user.likes.includes(:song).map(&:song)

    render :layout => false, :template => "visualizer"
  end

private

  def cookie_params
    if current_user
      raise "You can't be logged in"
    end

    @params = JSON.parse(cookies.signed[:auth])

    if !%w{provider uid info}.all?(&@params.method(:include?))
      raise "Missing params"
    end
  rescue
    load_fail
  end

  def load_fail
    redirect_to root_url
  end
end
