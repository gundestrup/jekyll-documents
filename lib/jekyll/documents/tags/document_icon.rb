# frozen_string_literal: true

module Jekyll
  module Documents
    class DocumentIconTag < Liquid::Tag
      public_class_method :new

      include Jekyll::Filters::URLFilters

      def initialize(tag_name, markup, tokens)
        super
        @document_expression, @options = parse_markup(markup)
      end

      def render(context)
        document = context.find_variable(@document_expression)
        return "" unless document

        @context = context
        icon_url = document_value(document, "icon_url") || fallback_icon(document, context)
        url = relative_url(icon_url)
        file_type = document_value(document, "file_type").to_s
        alt = @options["alt"] || "#{file_type.upcase} file"
        css_class = @options["class"] || "document-file-icon"

        style = "width:1em;height:1em;vertical-align:middle;"
        "<img src=\"#{escape_html(url)}\" alt=\"#{escape_html(alt)}\" " \
          "class=\"#{escape_html(css_class)}\" style=\"#{style}\" />"
      end

      private

      def document_value(document, key)
        return document.data[key] if document.respond_to?(:data)
        return document[key] if document.respond_to?(:[])

        nil
      end

      def fallback_icon(document, context)
        file_type = document_value(document, "file_type")
        icon_set = Configuration.read(context.registers[:site])["icon_set"]
        FileTypeIcons.icon_for(file_type, icon_set)
      end

      def parse_markup(markup)
        expression = markup.to_s.strip[/\A[^\s]+/]
        options = {}
        markup.to_s.scan(
          /(\w+)\s*:\s*(?:'([^']*)'|"([^"]*)"|([^\s]+))/
        ) do |key, single, double, bare|
          options[key] = single || double || bare
        end
        [expression, options]
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

Liquid::Template.register_tag("document_icon", Jekyll::Documents::DocumentIconTag)
