module OrderItemsHelper
  def format_name(input)
    safe_join(input.split(/(\d+ mg)/), tag.br)
  end
end
