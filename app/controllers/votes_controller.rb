class VotesController < ApplicationController
  def show
    head :not_found and return unless current_user

    votes = current_user.votes.all.group_by(&:award)
    Award.all.each do |award|
      votes[award] ||= [current_user.votes.new(:award_id => award.id)]
    end
    @votes = votes.values.map(&:first).sort_by { |g| g.award.id }
  end

  def update
    head :not_found and return unless current_user
    head :forbidden and return unless contest_in_progress

    current_vote = current_user.votes.where(:award_id => params[:vote][:award_id]).first
    current_vote ||= current_user.votes.new(vote_params)

    current_vote.update_attributes(vote_params)

    if current_vote.save
      head :no_content
    else
      head :bad_request
    end
  end

  private

  def vote_params
    params.require(:vote).permit(:award_id, :mixtape_id)
  end
end

