class AddVotingEnabled < ActiveRecord::Migration
  def change
    add_column :contests, :voting_enabled, :boolean, :default => false
  end
end
