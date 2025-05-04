class SupportEntry < ApplicationRecord
  validates :question, :answer, presence: true
end
