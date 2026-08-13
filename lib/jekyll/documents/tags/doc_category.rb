# frozen_string_literal: true

module Jekyll
  module Documents
    class DocCategoryTag < Liquid::Tag
      public_class_method :new

      include Jekyll::Filters::URLFilters

      def initialize(tag_name, markup, tokens)
        super
        @category, @options = parse_markup(markup)
      end

      def render(context)
        docs = documents_from(context)
        return "" if docs.empty?

        categories = available_categories(docs)
        category = resolve_category(@category, categories)
        return "" unless category

        @context = context
        return render_list(docs, category) if @options["list"] == "true"

        render_link(category)
      end

      private

      def documents_from(context)
        site = context.registers[:site]
        site.collections["documents"]&.docs || []
      end

      def available_categories(docs)
        docs.map { |doc| doc.data["category"].to_s }.uniq.sort
      end

      def resolve_category(query, categories)
        normalized = query.to_s.strip.downcase
        return nil if normalized.empty?

        categories.find { |cat| cat.downcase == normalized } ||
          categories.find { |cat| cat.downcase.include?(normalized) }
      end

      def render_link(category)
        url = relative_url("/documents/#{category}/")
        text = @options["text"] || category
        %(<a href="#{escape_html(url)}">#{escape_html(text)}</a>)
      end

      def render_list(docs, category)
        cat_docs = sorted_category_docs(docs, category)
        limit = @options["limit"]&.to_i
        cat_docs = cat_docs.first(limit) if limit&.positive?

        out = %(<ul class="doc-category-list" data-category="#{escape_html(category)}">\n)
        out << list_items(cat_docs)
        out << "</ul>\n"
      end

      def sorted_category_docs(docs, category)
        docs.select { |doc| doc.data["category"].to_s == category }
            .sort_by { |doc| doc.data["date"] || Time.at(0) }.reverse
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
