class Guess < ActiveRecord::Base
  attr_accessible :mixtape_id, :user_guessed_id

  validates_uniqueness_of :mixtape_id, :scope => :user_id

  belongs_to :mixtape
  belongs_to :user
  belongs_to :user, :foreign_key => :user_guessed_id

  default_scope includes(:mixtape)
end
