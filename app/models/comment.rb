class Comment < ActiveRecord::Base
  EDIT_CUTOFF = 1.hour

  attr_accessible :comment, :deleted

  belongs_to :user
  belongs_to :mixtape

  scope :latest, lambda { order('created_at desc').limit(5) }

  scope :after, lambda {|time|
    where('created_at > ?', time)
  }

  scope :today, lambda { after(Date.today.to_time) }

  default_scope lambda { where(:deleted => false) }

  validate :has_comment

  def destroy
    self.deleted = true
    save
  end

  def link_id
    mixtape.comments.index(self) + 1
  end

  def author
    user.name
  end

  def by_owner?
    belongs_to?(mixtape.user)
  end

  def belongs_to?(user)
    user && self.user_id == user.id
  end

  def editable_by?(user)
    belongs_to?(user) && Time.new - created_at < EDIT_CUTOFF
  end

  private

  def has_comment
    if comment.strip.length <= 0
      errors.add(:base, 'Message missing')
    end
  end
end
