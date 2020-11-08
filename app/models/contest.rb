class Contest < ActiveRecord::Base
  has_many :mixtapes, -> { order('lower(mixtapes.name)') }
  has_many :songs, through: :mixtapes
  has_many :guesses, through: :mixtapes
  has_many :votes, through: :mixtapes
  has_many :comments, through: :mixtapes
  has_many :participants, through: :mixtapes, source: :user

  def before?
    Time.new < start_date
  end

  def started?
    !before?
  end

  def in_progress?
    Time.new.between?(start_date, end_date)
  end

  def ended?
    Time.new > end_date
  end

  def rotation_seed
    Random.new(rotation_date.to_i)
  end

  def rotation_day
    # We align this day with the monday of the first week, and then we fit it to
    # a 5-day week where the weekends are not counted.
    offset = rotation_date.wday - 1
    days = (Time.now - rotation_date).to_i / 1.day + offset

    index = (days / 7) * 5 + (days % 7) - offset

    # We also have to take into account the exclusions defined in the settings.
    # If any of them fall between the contest time period and have passed, we
    # should decrement.
    index -= Settings.daily_exclusions.select do |date|
      date.to_time.between?(start_date, end_date) \
        && date < Date.today
    end.count

    return index
  end

  def daily_mix_day?
    [
      rotation_date < Time.now,
      !ended?,
      !Time.now.saturday?,
      !Time.now.sunday?,
      !Settings.daily_exclusions.include?(Date.today),
    ].all?
  end
end
