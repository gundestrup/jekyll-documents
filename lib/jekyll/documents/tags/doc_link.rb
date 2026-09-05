# frozen_string_literal: true

module Jekyll
  module Documents
    module DocumentResolver
      include ResolutionReporter

      private

      def find_document(docs, query, options, site)
        return find_document_by_path(docs, options["path"], site) if options["path"]

        normalized = query.to_s.strip.downcase
        return nil if normalized.empty?

        exact = docs.select { |doc| document_values(doc).include?(normalized) }
        matches = if exact.empty?
                    docs.select do |doc|
                      document_values(doc).any? { |value| value.include?(normalized) }
                    end
                  else
                    exact
                  end
        return matches.first if matches.one?
        return nil if matches.empty?

        paths = matches.map { |doc| doc.data["source_path"] || doc.path }.sort.join(", ")
        message = "Ambiguous doc_link #{query.inspect}; matches: #{paths}. Rendering nothing."
        report_resolution_issue(site, message)
        nil
      end

      def find_document_by_path(docs, path, site)
        normalized = normalize_identifier_path(path)
        matches = docs.select { |doc| doc.data["source_path"].to_s == normalized }
        return matches.first if matches.one?

        issue = matches.empty? ? "Unknown" : "Ambiguous"
        candidates = matches.map { |doc| doc.data["source_path"] }.sort.join(", ")
        detail = candidates.empty? ? normalized : candidates
        report_resolution_issue(site, "#{issue} doc_link path #{path.inspect}: #{detail}")
        nil
      end

      def normalize_identifier_path(path)
        path.to_s.strip.tr("\\", "/").squeeze("/").delete_prefix("./").delete_prefix("/")
            .delete_suffix("/")
      end

      def document_values(doc)
        [doc.data["title"], doc.data["slug"]].map { |value| value.to_s.downcase }
      end
    end

    class DocLinkTag < Liquid::Tag
      public_class_method :new

      include DocumentResolver
      include Jekyll::Filters::URLFilters

      SIZE_UNITS = %w[B KB MB GB].freeze

      def initialize(tag_name, markup, tokens)
        super
        @query, @options = parse_markup(markup)
      end

      def render(context)
        docs = documents_from(context)
        return "" if docs.empty?

        match = find_document(docs, @query, @options, context.registers[:site])
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
        "<img src=\"#{escape_html(url)}\" alt=\"#{file_type}\" " \
          "class=\"document-file-icon doc-link-icon\" " \
          "style=\"width:1em;height:1em;vertical-align:middle;\" />"
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
        return [nil, text] if text.strip.match?(/\Apath\s*:/)

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
