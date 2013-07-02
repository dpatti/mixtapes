class Comment < ActiveRecord::Base
  EDIT_CUTOFF = 1.hour

  attr_accessible :comment, :deleted

  belongs_to :user
  belongs_to :mixtape

  scope :undeleted, where(:deleted => false)

  def destroy
    self.deleted = true
    save
  end

  def link_hash
    "##{ link_id }"
  end

  def link_id
    mixtape.comments.index(self) + 1
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

  def editable_by?(user)
    belongs_to?(user) && Time.new - created_at < EDIT_CUTOFF
  end
end
