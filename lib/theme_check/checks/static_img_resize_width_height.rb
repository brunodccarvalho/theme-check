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
      extract_src_width_and_height_from_filter(node.attributes["src"].to_s) do |name, width, height|
        attr_width = node.attributes["width"]
        attr_height = node.attributes["height"]
        next if attr_width == width && attr_height == height

        add_offense("Expected width=#{width} and height=#{height} respecting the #{name} filter", node: node)
      end
    end

    private

    def extract_src_width_and_height_from_filter(attribute)
      visit_single_liquid_variable(attribute) do |variable|
        filter = variable.filters.find { |filter| RESIZE_FILTERS.include?(filter[0]) }
        next unless filter && filter[1].size == 1 # exactly one argument

        name, argument = filter[0], filter[1][0]
        next unless argument.is_a?(String) && argument =~ WIDTH_AND_HEIGHT

        width, height = Regexp.last_match[1..2]
        yield name, width, height
      end
    end
  end
end
