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

    def initialize(placeholders: %w[placeholder])
      @placeholders = placeholders
    end

    def on_img(node)
      src = node.attributes["src"].to_s
      placeholder, name, width, height = extract_src_width_and_height_from_filter(node, src)
      attr_width = node.attributes["width"]
      attr_height = node.attributes["height"]

      # Perfect match, all is fine
      return if width && height && attr_width == width && attr_height == height

      # Filter is present but attributes are not
      add_offense("Expected width=#{width} and height=#{height} respecting the #{name} filter", node: node) if width && height

      # Both attributes are integers, no filter, src is a variable, and there is no placeholder variable.
      return unless !placeholder && positive?(attr_width) && positive?(attr_height) && single_variable?(src)

      add_offense("Expected resize or thumb filter for #{attr_width}x#{attr_height}", node: node)
    end

    private

    def extract_src_width_and_height_from_filter(node, src)
      visit_single_liquid_variable(src) do |variable|
        placeholder = ([variable.name] + variable.filters.flatten).any? { |item| placeholder_lookup?(item) }
        index = variable.filters.find_index { |(name)| RESIZE_FILTERS.include?(name) }
        next placeholder unless index

        check_lookups_before_filter(node, variable, index)

        filter = variable.filters[index]
        next placeholder unless filter[1].size == 1 # exactly one argument

        name, argument = filter[0], filter[1][0]
        next placeholder unless argument.is_a?(String) && argument =~ WIDTH_AND_HEIGHT

        width, height = Regexp.last_match[1..2]
        next placeholder, name, width, height
      end
    end

    def check_lookups_before_filter(node, variable, index)
      filter = variable.filters[index][0]

      if placeholder_lookup?(variable.name)
        markup = recover_variable_markup(variable.name)
        add_offense("Apparent placeholder '#{markup}' piped into a #{filter} filter", node: node)
      end
      variable.filters[0...index].each do |(name, args)|
        if name == 'default' && placeholder_lookup?(args[0])
          markup = recover_variable_markup(variable.name)
          add_offense("Apparent placeholder '#{markup}' piped into a #{filter} filter", node: node)
        end
      end
    rescue StandardError
      byebug
    end

    def positive?(attribute)
      attribute && attribute.match?(/\A\d+\z/) && attribute.to_i.positive?
    end

    def placeholder_lookup?(variable_lookup)
      variable_lookup.is_a?(Liquid::VariableLookup) && @placeholders.any? { |pattern| variable_lookup.name.include?(pattern) }
    end
  end
end
