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

      def parse_args(markup)
        # supports: count:5 category:'referat'
        args = {}
        # Safe: markup comes from Jekyll template authors (trusted), not end users
        # Runs only during static site generation, not on user requests
        markup.scan(/(\w+)\s*:\s*'([^']*)'|(\w+)\s*:\s*([^\s]+)/).each do |match|
          if match[0]
            args[match[0]] = match[1]
          else
            args[match[2]] = match[3]
          end
        end
        args
      end
    end
  end
end

Liquid::Template.register_tag("latest_documents", Jekyll::Documents::LatestDocumentsTag)
