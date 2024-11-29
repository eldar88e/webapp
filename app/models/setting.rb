class Setting < ApplicationRecord
  validates :variable, presence: true, uniqueness: true
end
