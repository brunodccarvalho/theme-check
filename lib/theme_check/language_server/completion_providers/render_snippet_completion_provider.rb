# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class RenderSnippetCompletionProvider < CompletionProvider
      def completions(context)
        content = context.content
        cursor = context.cursor

        return [] if content.nil?
        return [] unless cursor_on_quoted_argument?(content, cursor)
        partial = snippet(content) || ''
        context.theme_view
          .files
          .select { |x| x.include?('partials/') }
          .select { |x| x.start_with?(partial) }
          .map { |x| snippet_to_completion(x) }
      end

      private

      def cursor_on_quoted_argument?(content, cursor)
        match = content.match(PARTIAL_RENDER)
        return false if match.nil?
        match.begin(:partial) <= cursor && cursor <= match.end(:partial)
      end

      def snippet(content)
        match = content.match(PARTIAL_RENDER)
        return if match.nil?
        match[:partial]
      end

      def snippet_to_completion(file)
        {
          label: File.basename(file, '.liquid'),
          kind: CompletionItemKinds::SNIPPET,
          detail: file,
        }
      end
    end
  end
end
