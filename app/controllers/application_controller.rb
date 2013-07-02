class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :before_contest, :contest_started, :contest_ended

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

  def before_contest
    Time.new < Settings.contest.start
  end

  def contest_started
    not before_contest
  end

  def contest_ended
    Time.new > Settings.contest.end
  end

  def send_file(path, opts={})
    if Settings.use_xsendfile
      head :x_accel_redirect => "/#{ path }",
           :content_type => "application/octet-stream",
           :content_disposition => "attachment; filename=\"#{opts[:filename]}\""
    else
      super
    end
  end
end
