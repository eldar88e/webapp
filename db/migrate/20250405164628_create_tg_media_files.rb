class CreateTgMediaFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :tg_media_files do |t|
      t.string :file_id
      t.string :file_hash, null: false, index: { unique: true }
      t.string :file_type
      t.string :original_filename

      t.timestamps
    end
  end
end
