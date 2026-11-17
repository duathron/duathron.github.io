# frozen_string_literal: true

# Jekyll Plugin: Foldable Obsidian callouts -> <details>
#
# Source .md files stay unchanged; the conversion happens only at build time.
#
# Supported syntax (foldable callouts only):
#   > [!note]- Title     -> collapsed <details>
#   > [!note]+ Title     -> open <details>
#   > body line          (every directly following line starting with ">")
#
# Callouts without +/- are left untouched. Nested callouts are not supported
# (the body keeps its inner ">" text). Top-level fenced code blocks are skipped.

module Jekyll
  class CalloutsToDetails
    HEADER = /\A> \[!([A-Za-z][A-Za-z0-9_-]*)\]([+-])[ \t]*(.*?)[ \t]*\z/.freeze
    FENCE = /\A {0,3}(`{3,}|~{3,})(.*)\z/.freeze

    DETAILS_STYLE = 'border: 1px solid rgba(128,128,128,0.35); border-radius: 6px; ' \
                    'padding: 0.75em 1em; margin: 1em 0;'
    SUMMARY_STYLE = 'cursor: pointer; font-weight: 600;'
    BODY_STYLE = 'margin-top: 0.75em; padding-top: 0.75em; ' \
                 'border-top: 1px solid rgba(128,128,128,0.25);'

    class << self
      def convert(content)
        return content unless content.match?(/^> \[![A-Za-z][A-Za-z0-9_-]*\][+-]/)

        lines = content.split(/\r?\n/, -1)
        out = []
        fence = nil # [char, length] while inside a top-level fence
        skip_blank = false
        i = 0

        while i < lines.length
          line = lines[i]

          if skip_blank
            skip_blank = false
            if line.empty?
              i += 1
              next
            end
          end

          if fence
            fence = nil if closes_fence?(line, fence)
            out << line
            i += 1
            next
          end

          if (m = FENCE.match(line))
            fence = [m[1][0], m[1].length]
            out << line
            i += 1
            next
          end

          header = HEADER.match(line)
          unless header
            out << line
            i += 1
            next
          end

          body = []
          i += 1
          while i < lines.length && lines[i].start_with?('>')
            body << lines[i].sub(/\A> ?/, '')
            i += 1
          end

          out << '' unless out.empty? || out.last.empty?
          out.concat(render(header[1], header[2], header[3], body))
          out << ''
          skip_blank = true
        end

        out.join("\n")
      end

      def render(type, fold, title, body)
        title = type[0].upcase + type[1..-1] if title.empty?
        open_attr = fold == '+' ? ' open' : ''
        ["<details style=\"#{DETAILS_STYLE}\"#{open_attr}>",
         "<summary style=\"#{SUMMARY_STYLE}\">#{escape(title)}</summary>",
         "<div markdown=\"1\" style=\"#{BODY_STYLE}\">",
         '',
         *body,
         '',
         '</div>',
         '</details>']
      end

      private

      def closes_fence?(line, fence)
        m = FENCE.match(line)
        m && m[1][0] == fence[0] && m[1].length >= fence[1] && m[2].strip.empty?
      end

      def escape(text)
        text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
      end
    end
  end
end

Jekyll::Hooks.register :posts, :pre_render do |post, _payload|
  post.content = Jekyll::CalloutsToDetails.convert(post.content)
end
