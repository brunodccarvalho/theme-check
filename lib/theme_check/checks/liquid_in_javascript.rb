# frozen_string_literal: true
module ThemeCheck
  # Forbids usage of liquid constructs inside a <script> tag with source in the javascript language.
  class LiquidInJavascript < HtmlCheck
    include RegexHelpers

    severity :suggestion
    category :html
    doc docs_url(__FILE__)

    JAVASCRIPT_MIME_TYPES = %w[
      application/javascript
      application/ecmascript
      text/javascript
      text/ecmascript
    ].freeze

    def on_script(node)
      type = node.attributes["type"]
      return if type && !JAVASCRIPT_MIME_TYPES.include?(type)

      node.children.filter_map { |child| child if child.name == "text" }.each do |text_node|
        matches(text_node.markup, LIQUID_TAG_OR_VARIABLE).each do |match|
          add_offense('Avoid mixing liquid constructs in javascript. ' +
            'Consider alternative approaches like writing liquid values in html attributes or in a <script type="application/json"> element.',
            node: text_node, markup: match[0], node_markup_offset: match.begin(0))
        end
      end
    end
  end
end
