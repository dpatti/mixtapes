class Award
  include ActiveModel::Model

  attr_accessor :id, :title

  def self.all
    @all ||= [
      new(id: 1, title: "Best individual songs"),
      new(id: 2, title: "Best flow"),
      new(id: 3, title: "Most variety"),
      new(id: 4, title: "Most adventurous"),
      new(id: 5, title: "Most likely to win a mixtape competition"),
    ]
  end
end
