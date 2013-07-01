class Comment < ActiveRecord::Base
  attr_accessible :comment, :deleted

  belongs_to :user
  belongs_to :mixtape

  default_scope where(:deleted => false)

  def destroy
    self.deleted = true
    save
  end

  def author
    "anonymous"
  end

  def by_owner?
    belongs_to?(mixtape.user)
  end

  def belongs_to?(user)
    self.user_id == user.id
  end
end
