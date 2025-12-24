module Admin
  class IconComponent < ViewComponent::Base
    include ViteRails::TagHelpers

    def initialize(name:, width: 20, height: nil, klass: nil)
      super()
      @name   = name
      @width  = width
      @height = height || width
      @klass  = klass
    end
  end
end
