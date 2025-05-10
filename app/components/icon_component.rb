class IconComponent < ViewComponent::Base
  def initialize(name:, size: 20)
    super()
    @name = name
    @size = size
  end
end
