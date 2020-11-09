class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :current_contest, :contest_context, :voting_warning, :log_in

  before_filter :record_user_activity
  before_filter :prepare_navbar

  def index
    # Home gets the special no-subtitle title
    @title = nil
    render "home"
  end

  def refuse_access
    render "refuse_access"
  end

  def require_password
    render "require_password"
  end

  private

  def current_contest
    # XXX: Maybe one day
    nil
  end

  # Also overridden in other controllers
  def contest_context
    @contest_context ||= begin
      if params[:contest_id]
        Contest.find(params[:contest_id])
      end
    end
  end

  def voting_warning
    left = Settings.contest.end - Time.new
    left.between?(0, 14.days) ? (left / 1.day).to_i : nil
  end

  def current_user
    @current_user ||= begin
      User.find(session[:user_id])
    rescue ActiveRecord::RecordNotFound
      nil
    end if session[:user_id]
  end

  def send_file(path, opts={})
    # Make sure file is readable; rubyzip creates as 0600. This should be
    # somewhere else but Zip is in two places.
    FileUtils.chmod(0664, path)

    if Settings.use_xsendfile
      extension = File.extname(opts[:filename]).downcase[1..-1]
      head :x_accel_redirect => path,
           :content_type => Mime::Type.lookup_by_extension(extension),
           :content_disposition => "attachment; filename=\"#{opts[:filename]}\""
    else
      super
    end
  end

  def record_user_activity
    if current_user
      current_user.touch :accessed_at
    end
  end

  def prepare_navbar
    @navbar_label = contest_context&.name || "Mixtapes"
    @navbar_contests = Contest.all
  end

  def log_in(user)
    session[:user_id] = user.id
    redirect_to root_url, flash: { success: "Signed in!" }
  end
end
