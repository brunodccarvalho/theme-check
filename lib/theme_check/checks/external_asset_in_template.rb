# frozen_string_literal: true
module ThemeCheck
  # Enforce that external stylesheet and script assets are only used in templates
  class ExternalAssetInTemplate < HtmlCheck
    include RegexHelpers
    severity :error
    category :html
    doc docs_url(__FILE__)

    def on_script(node)
      return unless node.attributes["src"] && !node.theme_file.template?

      add_offense("External script assets should only be included in templates", node: node)
    end

    def on_link(node)
      return unless node.attributes["href"] && !node.theme_file.template?

      add_offense("External script assets should only be included in templates", node: node)
    end
  end
end
