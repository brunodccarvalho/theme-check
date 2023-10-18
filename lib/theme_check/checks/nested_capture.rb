# frozen_string_literal: true
module ThemeCheck
  # Checks usage of captures or assigns inside a {% capture x %}...{% endcapture %} tag.
  class NestedCapture < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def on_document(_node)
      @stack_counter = 0
    end

    def on_assign(node)
      add_offense("Move assign out of capture", node: node) if @stack_counter > 0
    end

    def on_capture(node)
      add_offense("Move nested capture out of parent capture", node: node) if @stack_counter > 0
      @stack_counter += 1
    end

    def after_capture(_node)
      @stack_counter -= 1
    end

    def after_document(_node)
      @stack_counter = 0
    end
  end
end
