class Guess < ActiveRecord::Base
  validates_uniqueness_of :mixtape_id, :scope => :user_id

  belongs_to :mixtape
  belongs_to :user
  belongs_to :user, :foreign_key => :user_guessed_id

  default_scope -> { includes(:mixtape) }

  def self.non_self
    all.reject { |g| g.user_id == g.mixtape&.user&.id }
  end
end
