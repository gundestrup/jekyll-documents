# frozen_string_literal: true

module Jekyll
  module Documents
    # Shared markup parsing, document collection access, path
    # normalization, and HTML escaping for the Liquid tags.
    module TagHelpers
      private

      def parse_markup(markup)
        text = markup.to_s
        target, remainder = extract_target(text)
        options = extract_options(remainder)
        [target, options]
      end

      def extract_target(text)
        return [nil, text] if text.strip.match?(/\Apath\s*:/)

        quoted = text.match(/\A["']([^"']+)["']/)
        return [quoted[1], text[quoted.end(0)..]] if quoted

        bare = text.strip.match(/\A([^\s]+)/)
        return [nil, ""] unless bare

        [bare[1], text[bare.end(0)..]]
      end

      def extract_options(text)
        OptionsParser.parse_options(text)
      end

      def documents_from(context)
        site = context.registers[:site]
        site.collections["documents"]&.docs || []
      end

      def normalize_tag_path(path)
        path.to_s.strip.tr("\\", "/").squeeze("/").delete_prefix("./").delete_prefix("/")
            .delete_suffix("/")
      end

      def escape_html(value)
        value.to_s.gsub(/[&<>"']/,
                        "&" => "&amp;",
                        "<" => "&lt;",
                        ">" => "&gt;",
                        '"' => "&quot;",
                        "'" => "&#39;")
      end
    end
  end
end
