# frozen_string_literal: true
module ThemeCheck
  # Checks trivial usages of captures that should probably be assigns.
  class TrivialCapture < LiquidCheck
    include LiquidHelper
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def on_capture(node)
      nodelist = stripped_nodelist(node.value.nodelist)
      add_offense('Empty capture', node: node) if node.value.nodelist.all?(String) && node.value.nodelist.join.strip.empty?
      add_offense('Replace string body with single line assign', node: node) if node.value.nodelist.all?(String) && !node.value.nodelist.join.strip.include?("\n")
      add_offense('Replace variable body with single line assign', node: node) if nodelist.size == 1 && nodelist.first.is_a?(Liquid::Variable)
    end
  end
end
