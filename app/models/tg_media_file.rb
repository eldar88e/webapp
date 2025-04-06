class TgMediaFile < ApplicationRecord
  has_one_attached :attachment, dependent: :purge

  validates :file_hash, presence: true
  validates :file_hash, uniqueness: true

  def image?
    file_type.start_with?('image')
  end

  def video?
    file_type.start_with?('video')
  end
end
