class CreateLists < ActiveRecord::Migration[4.2]
  def change
    create_table :lists do |t|
      t.string :name
      t.text :variable_ids
      t.integer :user_id

      t.timestamps
    end
  end
end
