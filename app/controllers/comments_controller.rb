class CommentsController < ApplicationController
  def create
    refuse_access and return unless current_user
    @comment = Comment.new(params[:comment]) do |c|
      c.user_id = current_user.id
      c.mixtape_id = params[:mixtape_id]
    end

    @comment.save
    redirect_to mixtape_path(params[:mixtape_id])
  end

  def update
    @comment = Comment.find(params[:id])
    refuse_access and return unless @comment.belongs_to? current_user

    @comment.update_attributes(params[:comment])
    head :no_content
  end

  def destroy
    @comment = Comment.find(params[:id])
    refuse_access and return unless @comment.belongs_to? current_user

    @comment.destroy
    head :no_content
  end
end
