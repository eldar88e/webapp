class IconComponent < ViewComponent::Base
  include ViteRails::TagHelpers

  def initialize(name:, size: 20)
    super()
    @name = name
    @size = size
  end
end
