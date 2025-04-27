class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :answer_options, dependent: :destroy

  validates :text, presence: true, length: { minimum: 10 }
end
