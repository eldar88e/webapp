module OrderItemsHelper
  def format_name(input)
    input.gsub(/(.*?)(\d+ mg)/, '\\1<br>\\2').html_safe
  end
end
