# frozen_string_literal: true

module Jekyll
  module Documents
    class LatestDocumentsTag < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
        @args = parse_args(markup)
      end

      def render(context)
        site = context.registers[:site]
        cfg  = Configuration.read(site)
        count = (@args["count"] || cfg["latest_default_count"] || 5).to_i
        category = @args["category"]

        docs = site.collections["documents"]&.docs || []
        docs = docs.select { |d| d.data["category"] == category } if category
        docs = docs.sort_by { |d| d.data["date"] || Time.at(0) }.reverse.first(count)

        out = +"<ul class=\"latest-documents\">\n"
        docs.each do |d|
          title = d.data["title"]
          url   = d.url
          date  = (d.data["date"] || Time.at(0)).strftime("%d-%m-%Y")
          out << %(<li>#{url}#{title}</a> <small>(#{date})</small></li>\n)
        end
        out << "</ul>\n"
        out
      end

      private

      def parse_args(markup)
        # supports: count:5 category:'referat'
        args = {}
        markup.scan(/(\w+)\s*:\s*'([^']*)'|(\w+)\s*:\s*([^\s]+)/).each do |m|
          if m[0]
            args[m[0]] = m[1]
          else
            args[m[2]] = m[3]
          end
        end
        args
      end
    end
  end
end

Liquid::Template.register_tag("latest_documents", Jekyll::Documents::LatestDocumentsTag)
