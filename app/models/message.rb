class Message < ApplicationRecord
  belongs_to :user, primary_key: :tg_id, foreign_key: :tg_id

  ransacker :user_first_name do
    Arel.sql("users.first_name")
  end

  ransacker :user_middle_name do
    Arel.sql("users.middle_name")
  end

  ransacker :user_last_name do
    Arel.sql("users.last_name")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[user_first_name user_middle_name user_last_name created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
