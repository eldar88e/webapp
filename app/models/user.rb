class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :orders, dependent: :destroy
  has_one :cart, dependent: :destroy

  def cart
    super || create_cart
  end

  def full_name
    "#{middle_name} #{first_name} #{last_name}"
  end
end
