class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :content, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5, message: 'должен быть от 1 до 5' }
end
