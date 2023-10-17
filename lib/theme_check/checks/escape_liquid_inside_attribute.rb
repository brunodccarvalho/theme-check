# frozen_string_literal: true
module ThemeCheck
  # Check for an escape filter at the end of a liquid variable inside one of a fixed html attribute set
  class EscapeLiquidInsideAttribute < HtmlCheck
    include RegexHelpers
    severity :suggestion
    category :html
    doc docs_url(__FILE__)

    DEFAULT_ATTRIBUTES = %w[alt caption placeholder summary title].freeze
    DEFAULT_PATTERN = %r{\{\{.*?
      (?:\boptions\.\w[\w-]*(?:\.alt|\[['"]alt['"]\])? | option\.placeholder | (field|cfv|custom_field_value)\.value)
      \s*\}\}
    }x

    def initialize(attributes: [], pattern: nil)
      @attributes = attributes.empty? ? DEFAULT_ATTRIBUTES : attributes
      @patterns = make_patterns(pattern)
    end

    def on_element(node)
      node.attributes.each do |attr, value|
        next unless @attributes.include?(attr)

        matches(value, LIQUID_VARIABLE).each do |match|
          variable = Liquid::Template.parse(match[0]).root.nodelist.first
          next if variable.filters.include?('escape')
          next unless @patterns.any? { |p| match[0].match?(p) }

          add_offense('Escape liquid variables inside html attributes',
              node: node, markup: match[0], node_markup_offset: match.begin(0)) do |corrector|
            ms = node.markup.scan(match[0])
            next unless ms.size == 1

            escaped_match = match[0].sub(/\s*\}\}/, ' | escape }}')
            corrector.replace(node, node.markup.sub(match[0], escaped_match))
          end
        end
      rescue Liquid::SyntaxError
        # do nothing
      end
    end

    private

    def make_patterns(pattern)
      case pattern
      when String then [Regexp.new(pattern)]
      when Array then pattern.map { |p| Regexp.new(p) }
      else [DEFAULT_PATTERN]
      end
    end
  end
end
