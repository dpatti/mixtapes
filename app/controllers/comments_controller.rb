class CommentsController < ApplicationController
  def create
    refuse_access and return unless current_user
    mixtape = Mixtape.find(params[:mixtape_id])
    refuse_access and return unless mixtape.can_comment?

    @comment = Comment.new(comment_params) do |c|
      c.user_id = current_user.id
      c.mixtape = mixtape
    end

    @comment.save
    redirect_to mixtape_path(params[:mixtape_id])
  end

  def update
    @comment = Comment.find(params[:id])
    refuse_access and return unless @comment.editable_by? current_user

    @comment.update_attributes(comment_params)
    head :no_content
  end

  def destroy
    @comment = Comment.find(params[:id])
    refuse_access and return unless @comment.editable_by? current_user

    @comment.destroy
    head :no_content
  end

  private

  def comment_params
    params.require(:comment).permit(:comment, :deleted)
  end
end
