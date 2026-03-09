# frozen_string_literal: true

require "date"

module Jekyll
  module Documents
    class Generator < ::Jekyll::Generator
      safe true
      priority :normal

      def generate(site)
        @site   = site
        @config = Configuration.read(site)

        root = File.join(site.source, @config["root"])
        unless Dir.exist?(root)
          ::Jekyll.logger.warn "jekyll-documents", "Directory not found: #{root}"
          return
        end

        collection = ensure_collection(site, "documents")

        Dir.glob("#{root}/**/*").each do |path|
          next unless File.file?(path)

          ext = File.extname(path).downcase
          if @config["strict_extensions"] && !@config["include_extensions"].include?(ext)
            ::Jekyll.logger.abort_with "jekyll-documents",
                                       "Unsupported file type: #{path} (#{ext})"
          end
          next unless @config["include_extensions"].include?(ext)

          rel_path = path.sub(site.source + "/", "")
          category = infer_category_from(rel_path)
          basename = File.basename(path, ext)

          date, title, valid = parse_filename(basename)
          if !valid && @config["strict_filename"]
            ::Jekyll.logger.abort_with "jekyll-documents",
              "Filename must be 'YYYY-MM-DD_Title.ext' → #{rel_path}"
          end

          slug = build_slug(basename)

          doc = ::Jekyll::Document.new(
            source_stub_for(basename, category),
            site: site,
            collection: collection
          )

          doc.data["layout"]     = @config["layout"]
          doc.data["title"]      = title
          doc.data["date"]       = date || File.mtime(path)
          doc.data["category"]   = remap_category(category)
          doc.data["file_url"]   = "/" + rel_path
          doc.data["extension"]  = ext
          doc.data["slug"]       = slug
          doc.data["permalink"]  = @config["permalink"]
            .gsub(":category", doc.data["category"].to_s)
            .gsub(":slug", slug)

          doc.content = "Auto-generated document page."

          collection.docs << doc
        end
      end

      private

      def ensure_collection(site, label)
        site.collections[label] ||= ::Jekyll::Collection.new(site, label)
      end

      def source_stub_for(basename, category)
        File.join("_documents", "#{category}-#{basename}.md")
      end

      def infer_category_from(rel_path)
        return "uncategorized" unless @config["categories_from_path"]
        File.dirname(rel_path).split("/").last || "uncategorized"
      end

      def remap_category(cat)
        map = @config["category_map"] || {}
        (map[cat] || cat).to_s.downcase
      end

      # Returns [date, title, valid_format?]
      def parse_filename(basename)
        if basename =~ /^(\d{4})-(\d{2})-(\d{2})_(.+)$/
          date = Date.parse("#{Regexp.last_match(1)}-#{Regexp.last_match(2)}-#{Regexp.last_match(3)}")
          title = Regexp.last_match(4).tr("_", " ")
          [date, title, true]
        else
          [nil, basename.tr("_", " "), false]
        end
      rescue ArgumentError
        [nil, basename.tr("_", " "), false]
      end

      def build_slug(basename)
        s = basename.sub(/^\d{4}-\d{2}-\d{2}_/, "")
        s = s.gsub(/[æøåÆØÅ]/, {"æ"=>"ae","ø"=>"oe","å"=>"aa","Æ"=>"Ae","Ø"=>"Oe","Å"=>"Aa"}) if @config["slug_danish_map"]
        s = s.downcase if @config["slug_downcase"]
        s = s.gsub(/[^\p{Alnum}\-_\s]/u, "").tr(" ", "-").gsub(/-+/, "-")
        s
      end
    end
  end
end
