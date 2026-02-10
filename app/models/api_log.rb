class ApiLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true, optional: true
end
