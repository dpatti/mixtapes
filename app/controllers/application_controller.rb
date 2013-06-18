class ApplicationController < ActionController::Base
  protect_from_forgery

  def refuse_access
    render "refuse_access"
  end

  def pre_contest
    Time.new < Settings.contest.start
  end

  def during_contest
    Time.new.between?(Settings.contest.start, Settings.contest.end)
  end
end
