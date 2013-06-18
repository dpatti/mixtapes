class CreateMixtapes < ActiveRecord::Migration
  def change
    create_table :mixtapes do |t|
      t.string :name
      t.binary :cover
      t.string :owner
      t.string :password

      t.timestamps
    end
  end
end
