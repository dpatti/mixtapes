class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :pre_contest, :during_contest

  def index
    render "home"
  end

  def refuse_access
    render "refuse_access"
  end

  def require_password
    render "require_password"
  end

  private
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def pre_contest
    Time.new < Settings.contest.start
  end

  def during_contest
    Time.new.between?(Settings.contest.start, Settings.contest.end)
  end
end
