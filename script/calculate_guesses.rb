User.all.each do |user| 
  guesses = user.guesses.includes(:mixtape).all 
  next if guesses.size == 0 
 
  score = guesses.map do |g| 
    g.user_guessed_id == g.mixtape.user_id ? 1 : 0 
  end.reduce(:+) 
 
  guesses_for = -1 
  if user.mixtape 
    guesses_for = Guess.where(:mixtape_id => user.mixtape.id).map do |g| 
      g.user_guessed_id == user.id ? 1 : 0 
    end.reduce(:+) 
  end 
 
  puts "User: #{ user.name } - Score: #{ score } - Guesses for: #{ guesses_for }" 
end 

