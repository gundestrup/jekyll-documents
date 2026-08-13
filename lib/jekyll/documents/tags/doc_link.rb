# frozen_string_literal: true

module Jekyll
  module Documents
    class DocLinkTag < Liquid::Tag
      public_class_method :new

      include Jekyll::Filters::URLFilters

      SIZE_UNITS = %w[B KB MB GB].freeze

      def initialize(tag_name, markup, tokens)
        super
        @query, @options = parse_markup(markup)
      end

      def render(context)
        docs = documents_from(context)
        return "" if docs.empty?

        match = find_document(docs, @query)
        return "" unless match

        @context = context
        url = relative_url(match.url)
        text = @options["text"] || match.data["title"]

        build_link(match, url, text)
      end

      private

      def documents_from(context)
        site = context.registers[:site]
        site.collections["documents"]&.docs || []
      end

      def find_document(docs, query)
        normalized = query.to_s.strip.downcase
        return nil if normalized.empty?

        docs.find { |doc| matches?(doc, normalized) }
      end

      def matches?(doc, query)
        title = doc.data["title"].to_s.downcase
        slug = doc.data["slug"].to_s.downcase
        title == query || slug == query ||
          title.include?(query) || slug.include?(query)
      end

      def build_link(doc, url, text)
        inner = +""
        inner << icon_html(doc) if @options["icon"] != "false"
        inner << %(<span class="doc-link-title">#{escape_html(text)}</span>)
        inner << size_html(doc) if @options["size"] != "false"
        %(<a href="#{escape_html(url)}" class="doc-link">#{inner}</a>)
      end

      def icon_html(doc)
        icon_url = doc.data["icon_url"]
        return "" unless icon_url

        url = relative_url(icon_url)
        file_type = doc.data["file_type"].to_s.upcase
        "<img src=\"#{escape_html(url)}\" alt=\"#{file_type}\" class=\"file-icon doc-link-icon\" />"
      end

      def size_html(doc)
        size = doc.data["file_size"]
        return "" unless size

        "<span class=\"doc-link-size has-text-grey is-size-7\">#{format_size(size)}</span>"
      end

      def format_size(bytes)
        return "0 B" unless bytes&.positive?

        value, unit = compute_size(bytes)
        unit == "B" ? "#{value.to_i} B" : format("%<value>.1f %<unit>s", value:, unit:)
      end

      def compute_size(bytes)
        value = bytes.to_f
        SIZE_UNITS.each do |unit|
          return [value, unit] if value < 1024 || unit == SIZE_UNITS.last

          value /= 1024
        end
      end

      def parse_markup(markup)
        text = markup.to_s
        query, remainder = extract_query(text)
        options = extract_options(remainder)
        [query, options]
      end

      def extract_query(text)
        quoted = text.match(/\A["']([^"']+)["']/)
        return [quoted[1], text[quoted.end(0)..]] if quoted

        bare = text.strip.match(/\A([^\s]+)/)
        return [nil, ""] unless bare

        [bare[1], text[bare.end(0)..]]
      end

      def extract_options(text)
        options = {}
        text.to_s.scan(
          /(\w+)\s*:\s*(?:'([^']*)'|"([^"]*)"|([^\s]+))/
        ) do |key, single, double, bare|
          options[key] = single || double || bare
        end
        options
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

Liquid::Template.register_tag("doc_link", Jekyll::Documents::DocLinkTag)
