class Scene
  attr_accessor :user, :contest

  def initialize(user, contest)
    @user = user
    @contest = contest
  end

  def logged_in?
    !!@user
  end

  def has_mixtape?
    !!mixtape
  end

  def mixtape
    @mixtape ||= user.mixtape_for(contest)
  end

  def pre_contest?
    contest.before?
  end
end
