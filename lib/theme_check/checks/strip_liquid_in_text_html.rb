# frozen_string_literal: true
module ThemeCheck
  # Ensure that the body of certain text tags like span and p, if they are liquid variables, are left and right stripped.
  class StripLiquidInTextHtml < HtmlCheck
    include RegexHelpers
    severity :suggestion
    category :html
    doc docs_url(__FILE__)

    LEFT_LIQUID = /^\s+(#{LIQUID_TAG_OR_VARIABLE})/mo
    RIGHT_LIQUID = /(#{LIQUID_TAG_OR_VARIABLE})\s+$/mo
    DEFAULT_ELEMENTS = %w[h1 h2 h3 h4 h5 h6 span small p b strong i em a q blockquote code pre ul ol li].freeze

    def initialize(elements: [])
      @elements = elements.empty? ? DEFAULT_ELEMENTS : elements
    end

    def on_element(node)
      return unless @elements.include?(node.name) && single_text_body?(node)
      lint_text_node_left(node.children[0])
      lint_text_node_right(node.children[0])
    end

    private

    def lint_text_node_left(node)
      return unless (match = node.value.match(LEFT_LIQUID))
      return if match[1].start_with?("{%-") || match[1].start_with?("{{-")

      add_offense("Left strip liquid as html text",
          node: node, markup: match[1], node_markup_offset: match.begin(1)) do |corrector|
        ms = node.markup.scan(match[1])
        next unless ms.size == 1

        escaped_match = match[1].sub(/^{{-/, '{{-').sub(/^{%-/, '{%-')
        corrector.replace(node, node.markup.sub(match[0], escaped_match))
      end
    end

    def lint_text_node_right(node)
      return unless (match = node.value.match(RIGHT_LIQUID))
      return if match[1].end_with?("-%}") || match[1].end_with?("-}}")

      add_offense("Right strip liquid as html text",
          node: node, markup: match[1], node_markup_offset: match.begin(1)) do |corrector|
        ms = node.markup.scan(match[1])
        next unless ms.size == 1

        escaped_match = match[1].sub(/-}}$/, '-}}').sub(/-%}$/, '-%}')
        corrector.replace(node, node.markup.sub(match[1], escaped_match))
      end
    end

    def single_text_body?(node)
      node.children.size == 1 && node.children[0].name == "text"
    end
  end
end
