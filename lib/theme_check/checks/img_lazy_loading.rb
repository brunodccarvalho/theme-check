# frozen_string_literal: true
module ThemeCheck
  class ImgLazyLoading < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    BANNED_ATTRIBUTES = %w[data-src data-srcset].freeze
    LAZYSIZE_SCRIPT_REGEX = /lazysize/.freeze

    def on_img(node)
      add_offense("Use loading=\"eager\" for images visible in the viewport on load and loading=\"lazy\" for others", node: node) unless node.attributes["loading"]
      add_offense("Remove data-src and data-srcset attributes", node: node) if BANNED_ATTRIBUTES.any? { |attr| node.attributes.key?(attr) }
    end

    def on_script(node)
      return unless node.attributes["src"].to_s.match?(LAZYSIZE_SCRIPT_REGEX)

      add_offense("Remove lazysizes script", node: node)
    end
  end
end
