class CreateContests < ActiveRecord::Migration
  def change
    create_table :contests do |t|
      t.string :name
      t.integer :year
      t.date :start_date
      t.date :rotation_date
      t.date :end_date

      t.timestamps null: false
    end
  end
end
