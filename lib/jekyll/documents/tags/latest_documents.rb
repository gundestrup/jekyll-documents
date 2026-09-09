# frozen_string_literal: true

module Jekyll
  module Documents
    class LatestDocumentsTag < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
        @args = parse_args(markup)
      end

      public_class_method :new

      def render(context)
        site = context.registers[:site]
        cfg  = Configuration.read(site)
        count = (@args["count"] || cfg["latest_default_count"] || 5).to_i
        category = @args["category"]

        docs = site.collections["documents"]&.docs || []
        docs = docs.select { |doc| doc.data["category"] == category } if category
        docs = docs.sort_by { |doc| doc.data["date"] || Time.at(0) }.reverse.first(count)

        out = +"<ul class=\"latest-documents\">\n"
        docs.each do |doc|
          data = doc.data
          title = escape_html(data["title"])
          url   = escape_html(doc.url)
          date  = (data["date"] || Time.at(0)).strftime("%Y-%m-%d")
          out << %(<li><a href="#{url}">#{title}</a> <small>(#{date})</small></li>\n)
        end
        out << "</ul>\n"
        out
      end

      private

      def escape_html(text)
        return "" unless text

        text.to_s.gsub(/[&<>"']/, {
                         "&" => "&amp;",
                         "<" => "&lt;",
                         ">" => "&gt;",
                         '"' => "&quot;",
                         "'" => "&#39;"
                       })
      end

      # supports: count:5 category:'referat'
      def parse_args(markup)
        OptionsParser.parse_options(markup)
      end
    end
  end
end

Liquid::Template.register_tag("latest_documents", Jekyll::Documents::LatestDocumentsTag)
