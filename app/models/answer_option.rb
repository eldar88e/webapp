class AnswerOption < ApplicationRecord
  belongs_to :question

  validates :text, presence: true, length: { minimum: 2 }
end
