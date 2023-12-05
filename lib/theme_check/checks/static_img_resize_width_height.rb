# frozen_string_literal: true
module ThemeCheck
  class StaticImgResizeWidthHeight < HtmlCheck
    include RegexHelpers
    include LiquidHelper
    severity :suggestion
    category :html
    doc docs_url(__FILE__)

    RESIZE_FILTERS = %w[resize thumb].freeze
    WIDTH_AND_HEIGHT = /\A(\d+)x(\d+)\z/

    def on_img(node)
      src = node.attributes["src"].to_s
      name, width, height = extract_src_width_and_height_from_filter(src)
      attr_width = node.attributes["width"]
      attr_height = node.attributes["height"]

      # Perfect match, all is fine
      return if width && height && attr_width == width && attr_height == height

      # Filter is present but attributes are not
      return add_offense("Expected width=#{width} and height=#{height} respecting the #{name} filter", node: node) if width && height

      # Both attributes are integers, no filter, src is a variable.
      return unless positive?(attr_width) && positive?(attr_height) && single_variable?(src)

      add_offense("Expected resize or thumb filter for #{attr_width}x#{attr_height}", node: node)
    end

    private

    def extract_src_width_and_height_from_filter(attribute)
      visit_single_liquid_variable(attribute) do |variable|
        filter = variable.filters.find { |filter| RESIZE_FILTERS.include?(filter[0]) }
        next unless filter && filter[1].size == 1 # exactly one argument

        name, argument = filter[0], filter[1][0]
        next unless argument.is_a?(String) && argument =~ WIDTH_AND_HEIGHT

        width, height = Regexp.last_match[1..2]
        return name, width, height
      end
    end

    def positive?(attribute)
      attribute && attribute.match?(/\A\d+\z/) && attribute.to_i.positive?
    end
  end
end
