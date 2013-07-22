class Guess < ActiveRecord::Base
  attr_accessible :mixtape_id, :user_guessed_id, :user_id
end
