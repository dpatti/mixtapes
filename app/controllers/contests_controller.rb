class ContestsController < ApplicationController
  def index
    @contests = Contest.all
  end

  def show
  end
end
