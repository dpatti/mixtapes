class UsersController < ApplicationController
  before_filter :cookie_params

  def new
    @user = User.new_from_omniauth(@params)
  end

  def create
    user = User.new_from_omniauth(@params)
    user.save!
    cookies.delete(:auth)
    log_in(user)
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
