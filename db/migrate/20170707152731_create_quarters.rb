class CreateQuarters < ActiveRecord::Migration[5.1]
  def change
    create_table :quarters do |t|
      t.integer :year, null: false
      t.integer :quarter_number, null: false
      t.bigint :bigint, null: false, default: 0
      t.bigint :regular_files, null: false, default: 0
      t.bigint :regular_file_size, null: false, default: 0
      t.bigint :regular_total_files, null: false, default: 0
      t.bigint :regular_total_file_size, null: false, default: 0
      t.timestamps
      t.index [:year, :quarter_number], unique: true
    end
  end
end
