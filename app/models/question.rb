class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :answer_options, dependent: :destroy
  accepts_nested_attributes_for :answer_options, allow_destroy: true, reject_if: :all_blank

  validates :text, presence: true, length: { minimum: 10 }
end
