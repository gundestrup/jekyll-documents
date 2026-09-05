# frozen_string_literal: true

module Jekyll
  module Documents
    module CategoryResolver
      include ResolutionReporter

      private

      def resolve_category(query, options, categories, site)
        return resolve_category_path(options["path"], categories, site) if options["path"]

        normalized = query.to_s.strip.downcase
        return nil if normalized.empty?

        exact = categories.select do |category|
          category_values(category).include?(normalized)
        end
        matches = exact.empty? ? partial_categories(categories, normalized) : exact
        aggregate = options["aggregate"] == "true" && options["list"] == "true"
        return matches if matches.one? || (aggregate && matches.any?)
        return nil if matches.empty?

        paths = matches.map { |category| category["path"] }.sort.join(", ")
        message = "Ambiguous doc_category #{query.inspect}; matches: #{paths}. Rendering nothing."
        report_resolution_issue(site, message)
        nil
      end

      def resolve_category_path(path, categories, site)
        normalized = normalize_category_path(path)
        matches = categories.select { |category| category["path"] == normalized }
        return matches if matches.one?

        issue = matches.empty? ? "Unknown" : "Ambiguous"
        report_resolution_issue(site,
                                "#{issue} doc_category path #{path.inspect}: #{normalized}")
        nil
      end

      def partial_categories(categories, query)
        categories.select do |category|
          category_values(category).any? { |value| value.include?(query) }
        end
      end

      def category_values(category)
        leaf = category["path"].split("/").last.to_s.downcase
        [category["category"], category["slug"], leaf].map { |value| value.to_s.downcase }.uniq
      end

      def normalize_category_path(path)
        path.to_s.strip.tr("\\", "/").squeeze("/").delete_prefix("./").delete_prefix("/")
            .delete_suffix("/")
      end
    end

    class DocCategoryTag < Liquid::Tag
      public_class_method :new

      include CategoryResolver
      include Jekyll::Filters::URLFilters

      def initialize(tag_name, markup, tokens)
        super
        @category, @options = parse_markup(markup)
      end

      def render(context)
        docs = documents_from(context)
        return "" if docs.empty?

        categories = available_categories(docs)
        matches = resolve_category(@category, @options, categories, context.registers[:site])
        return "" unless matches

        @context = context
        return render_list(docs, matches) if @options["list"] == "true"

        render_link(matches)
      end

      private

      def documents_from(context)
        site = context.registers[:site]
        site.collections["documents"]&.docs || []
      end

      def available_categories(docs)
        categories = docs.group_by { |doc| doc.data["category_path"] || doc.data["category"] }
                         .map do |path, matches|
          data = matches.first.data
          { "path" => path.to_s, "category" => data["category"],
            "slug" => data["category_slug"] || data["category"] }
        end
        categories.sort_by { |category| category["path"] }
      end

      def render_link(matches)
        category = matches.first
        url = relative_url("/documents/#{category['slug']}/")
        text = @options["text"] || category["category"]
        %(<a href="#{escape_html(url)}">#{escape_html(text)}</a>)
      end

      def render_list(docs, matches)
        paths = matches.map { |category| category["path"] }
        cat_docs = sorted_category_docs(docs, paths)
        limit = @options["limit"]&.to_i
        cat_docs = cat_docs.first(limit) if limit&.positive?

        category = paths.join(",")
        out = %(<ul class="doc-category-list" data-category="#{escape_html(category)}">\n)
        out << list_items(cat_docs)
        out << "</ul>\n"
      end

      def sorted_category_docs(docs, paths)
        matches = docs.select do |doc|
          paths.include?((doc.data["category_path"] || doc.data["category"]).to_s)
        end
        matches.sort_by { |doc| doc.data["date"] || Time.at(0) }.reverse
      end

      def list_items(cat_docs)
        cat_docs.each_with_object(+"") do |doc, out|
          title = escape_html(doc.data["title"])
          url = escape_html(relative_url(doc.url))
          date = (doc.data["date"] || Time.at(0)).strftime("%Y-%m-%d")
          out << %(<li><a href="#{url}">#{title}</a> <small>(#{date})</small></li>\n)
        end
      end

      def parse_markup(markup)
        text = markup.to_s
        category, remainder = extract_category(text)
        options = extract_options(remainder)
        [category, options]
      end

      def extract_category(text)
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

Liquid::Template.register_tag("doc_category", Jekyll::Documents::DocCategoryTag)
