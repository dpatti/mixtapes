class LastRead < ActiveRecord::Base
  validates_uniqueness_of :user_id, :scope => :mixtape_id
  validates_presence_of :user_id, :mixtape_id

  def self.update_pair(user_id, mixtape_id)
    record =  where(:user_id => user_id, :mixtape_id => mixtape_id).first

    if record
      record.update_attribute('time', Time.new)
    else
      LastRead.create do |r|
        r.user_id = user_id
        r.mixtape_id = mixtape_id
        r.time = Time.new
      end
    end
  end
end
