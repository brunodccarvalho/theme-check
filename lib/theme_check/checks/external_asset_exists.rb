# frozen_string_literal: true
module ThemeCheck
  # Enforce that external assets exist and are loaded without issue
  class ExternalAssetExists < HtmlCheck
    include RegexHelpers
    severity :error
    category :html
    doc docs_url(__FILE__)

    def initialize(whitelist_patterns: [])
      @whitelist_patterns = whitelist_patterns
    end

    def on_script(node)
      check_exists(node, "src") if node.attributes["src"]
    end

    def on_link(node)
      check_exists(node, "href") if node.attributes["href"] && node.attributes["rel"] != "preconnect"
    end

    private

    def whitelisted?(src)
      @whitelist_patterns.any? { |p| src.include?(p) }
    end

    def visitable_src?(src)
      src =~ %r{^(https?:)?//} && no_liquid?(src)
    end

    def check_exists(node, attr)
      src = node.attributes[attr]
      return if !visitable_src?(src) || whitelisted?(src)

      asset = RemoteAssetFile.from_src(src)
      add_offense('Failed to fetch external asset', node: node) unless asset&.ok
    end
  end
end
