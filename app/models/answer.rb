class Answer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :answer_option, optional: true

  validates :user, uniqueness: { scope: :question, message: :already_answered }
end
