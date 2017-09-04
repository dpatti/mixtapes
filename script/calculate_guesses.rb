User.all.each do |user|
  guesses = user.guesses.includes(:mixtape).non_self

  score = -1
  if guesses.length > 0
    score = guesses.map do |g|
      g.user_guessed_id == g.mixtape.user_id ? 1 : 0
    end.reduce(0, :+)
  end

  guesses_for = -1
  if user.mixtape
    guesses_for = Guess.where(:mixtape_id => user.mixtape.id).non_self.map do |g|
      g.user_guessed_id == user.id ? 1 : 0
    end.reduce(0, :+)
  end

  if score > 0 || guesses_for >= 0
    puts "User: #{ user.name } - Score: #{ score } - Guesses for: #{ guesses_for }"
  end
end
