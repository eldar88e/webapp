class IconComponent < ViewComponent::Base
  def initialize(name:, size: 20)
    @name = name
    @size = size
  end
end
