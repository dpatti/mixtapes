class GuessesController < ApplicationController
  def show
    head :not_found and return unless current_user

    guesses = current_user.guesses.all.group_by(&:mixtape)
    Mixtape.with_songs.all.each do |mixtape|
      guesses[mixtape] ||= [current_user.guesses.new(:mixtape_id => mixtape.id)]
    end
    @guesses = guesses.values.map(&:first).sort_by {|g| g.mixtape.name}
    @options = User.includes(:mixtape).all.select(&:active?).sort_by(&:name)
  end

  def update
    head :not_found and return unless current_user
    head :forbidden and return unless contest_in_progress

    # Everything is a put, because a missing guess is implied NULL for
    # user_guessed_id
    current_guess = current_user.guesses.where(:mixtape_id => params[:guess][:mixtape_id]).first
    current_guess ||= current_user.guesses.new(guess_params)

    current_guess.update_attributes(guess_params)

    if current_guess.save
      head :no_content
    else
      head :bad_request
    end
  end

  private

  def guess_params
    params.require(:guess).permit(:mixtape_id, :user_guessed_id)
  end
end
