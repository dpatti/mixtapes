class Vote < ActiveRecord::Base
  belongs_to :user
  belongs_to :mixtape

  validates_uniqueness_of :award_id, :scope => :user_id

  def self.for_user(user, award:)
    self.user = user
    self.award = award
  end

  def award
    Award.all.find { |a| a.id == award_id }
  end

  def eligible_mixtapes
    Mixtape.with_songs.select { |m| m.voteable_by?(self.user) }
  end
end
