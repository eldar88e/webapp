class UserSerializer < Panko::Serializer
  attributes :id, :city, :full_name

  def city
    object.address
  end

  delegate :full_name, to: :object
end
