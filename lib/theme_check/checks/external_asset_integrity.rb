# frozen_string_literal: true
module ThemeCheck
  # Enforce that external assets without and script assets are only used in templates
  class ExternalAssetIntegrity < HtmlCheck
    include RegexHelpers
    severity :suggestion
    category :html
    doc docs_url(__FILE__)

    ALGORITHMS = %w[sha256 sha384 sha512]
    PREFERRED_ALGORITHM = 'sha256'
    LAX_VERSION = /\b(?:\d+)\.(?:\d+)\b/

    def initialize(algorithm: PREFERRED_ALGORITHM, whitelist_patterns: [])
      raise "Invalid integrity algorithm #{algorithm}" unless ALGORITHMS.include?(algorithm.to_s)

      @algorithm = algorithm.to_sym
      @whitelist_patterns = whitelist_patterns
    end

    def on_script(node)
      check_integrity(node, "src") if node.attributes["src"]
    end

    def on_link(node)
      check_integrity(node, "href") if node.attributes["href"] && node.attributes["rel"] != "preconnect"
    end

    private

    def whitelisted?(src)
      @whitelist_patterns.any? { |p| src.include?(p) }
    end

    def visitable_src?(src)
      src =~ %r{^(https?:)?//} && no_liquid?(src)
    end

    def check_integrity(node, attr)
      src = node.attributes[attr]
      return unless visitable_src?(src)
      # Require no integrity if the url appears to be unversioned.
      return check_no_integrity(node) unless src.match?(LAX_VERSION)
      # If the url is whitelisted don't require integrity. Check it anyway if it is there already.
      return if whitelisted?(src) && !node.attributes["integrity"] && !node.attributes["crossorigin"]

      RemoteAssetFile.visit_src(src) do |asset|
        integrities = content_integrities(asset.content)
        next if integrities.value?(node.attributes["integrity"]) && node.attributes["crossorigin"] == "anonymous"

        add_offense('Add or replace integrity/crossorigin attributes', node: node) do |corrector|
          integrity = integrities[@algorithm]
          repaired_markup = remove_attribute(node.markup, 'integrity')
          repaired_markup = remove_attribute(repaired_markup, 'crossorigin')
          repaired_markup = repaired_markup.delete_suffix('>')
          repaired_markup += " integrity=\"#{integrity}\""
          repaired_markup += ' crossorigin="anonymous">'
          corrector.replace(node, repaired_markup)
        end
      end
    end

    def check_no_integrity(node)
      if node.attributes["integrity"]
        add_offense('Remove integrity attribute of unversioned external asset', node: node) do |corrector|
          corrector.replace(node, remove_attribute(node.markup, 'integrity'))
        end
      end
      if node.attributes["crossorigin"]
        add_offense('Remove crossorigin attribute of unversioned external asset', node: node) do |corrector|
          corrector.replace(node, remove_attribute(node.markup, 'crossorigin'))
        end
      end
    end

    def content_integrities(content)
      {
        sha256: 'sha256-' + Base64.strict_encode64(Digest::SHA256.digest(content)),
        sha384: 'sha384-' + Base64.strict_encode64(Digest::SHA384.digest(content)),
        sha512: 'sha512-' + Base64.strict_encode64(Digest::SHA512.digest(content)),
      }
    end

    def remove_attribute(markup, attribute)
      markup.sub(/\s*\b#{Regexp.escape(attribute)}=(?:["][^"]+["]|['][^']+['])\s*/, ' ').sub(/^<\s+/, '').sub(/\s+>$/, '')
    end
  end
end
