class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :before_contest, :contest_started,
    :contest_ended, :contest_in_progress, :voting_warning, :log_in

  before_filter :record_user_activity

  def index
    if current_user && contest_started
      redirect_to mixtapes_path
    else
      render "home"
    end
  end

  def refuse_access
    render "refuse_access"
  end

  def require_password
    render "require_password"
  end

  private

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

  def before_contest
    Time.new < Settings.contest.start
  end

  def contest_started
    not before_contest
  end

  def contest_in_progress
    Time.new.between?(Settings.contest.start, Settings.contest.end)
  end

  def contest_ended
    Time.new > Settings.contest.end
  end

  def send_file(path, opts={})
    # Make sure file is readable; rubyzip creates as 0600. This should be
    # somewhere else but Zip is in two places.
    FileUtils.chmod(0664, path)

    if Settings.use_xsendfile
      extension = File.extname(opts[:filename]).downcase[1..-1]
      head :x_accel_redirect => "/#{ path }",
           :content_type => Mime::Type.lookup_by_extension(extension),
           :content_disposition => "attachment; filename=\"#{opts[:filename]}\""
    else
      super
    end
  end

  def rotation_seed
    Random.new(Settings.contest.rotation.to_i)
  end

  def rotation_day
    # We align this day with the monday of the first week, and then we fit it to
    # a 5-day week where the weekends are not counted.
    offset = Settings.contest.rotation.wday - 1
    days = (Time.now - Settings.contest.rotation).to_i / 1.day + offset

    index = (days / 7) * 5 + (days % 7) - offset

    # We also have to take into account the exclusions defined in the settings.
    # If any of them fall between the contest time period and have passed, we
    # should decrement.
    index -= Settings.daily_exclusions.select do |date|
      date.to_time.between?(Settings.contest.start, Settings.contest.end) \
        && date < Date.today
    end.count

    return index
  end

  def daily_mix_day?
    [
      Settings.contest.rotation < Time.now,
      !contest_ended,
      !Time.now.saturday?,
      !Time.now.sunday?,
      !Settings.daily_exclusions.include?(Date.today),
    ].all?
  end

  def record_user_activity
    if current_user
      current_user.touch :accessed_at
    end
  end

  def log_in(user)
    session[:user_id] = user.id
    redirect_to root_url, flash: { success: "Signed in!" }
  end
end
