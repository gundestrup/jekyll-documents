# frozen_string_literal: true

require "date"

module Jekyll
  module Documents
    # Main generator that scans document files and creates Jekyll collection items
    # @api public
    class Generator < ::Jekyll::Generator
      safe true
      priority :normal

      # Generates document collection from files in configured root directory
      # @param site [Jekyll::Site] the Jekyll site instance
      # @return [void]
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

          rel_path = path.start_with?(site.source) ? path[(site.source.length + 1)..] : path
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
          doc.data["file_url"]   = "/#{rel_path}"
          doc.data["extension"]  = ext
          doc.data["file_type"]  = ext.sub(".", "").downcase
          doc.data["slug"]       = slug
          doc.data["permalink"]  = @config["permalink"]
                                   .gsub(":category", doc.data["category"].to_s)
                                   .gsub(":slug", slug)

          doc.content = "Auto-generated document page."

          collection.docs << doc
        end
      end

      private

      # Ensures a collection exists and is configured for output
      # @param site [Jekyll::Site] the Jekyll site instance
      # @param label [String] the collection name
      # @return [Jekyll::Collection] the collection
      def ensure_collection(site, label)
        unless site.collections[label]
          site.collections[label] = ::Jekyll::Collection.new(site, label)
          site.config["collections"] ||= {}
          site.config["collections"][label] = { "output" => true }
        end
        site.collections[label]
      end

      # Creates a virtual source path for the document
      # @param basename [String] the file basename
      # @param category [String] the document category
      # @return [String] virtual source path
      def source_stub_for(basename, category)
        File.join("_documents", "#{category}-#{basename}.md")
      end

      # Infers category from the file's directory path
      # @param rel_path [String] relative path from site source
      # @return [String] the category name
      def infer_category_from(rel_path)
        return "uncategorized" unless @config["categories_from_path"]

        category_dir = File.dirname(rel_path).sub(@config["root"].to_s, "")
        category_dir.split("/").reject(&:empty?).last || "uncategorized"
      end

      # Remaps category name using category_map configuration
      # @param cat [String] the original category
      # @return [String] the remapped category (lowercased)
      def remap_category(cat)
        map = @config["category_map"] || {}
        (map[cat] || cat).to_s.downcase
      end

      # Parses filename to extract date and title
      # @param basename [String] the filename without extension
      # @return [Array<Date, String, Boolean>] date, title, and validity flag
      def parse_filename(basename)
        if basename =~ /^(\d{4})-(\d{2})-(\d{2})_(.+)$/
          date = Date.parse("#{Regexp.last_match(1)}-#{Regexp.last_match(2)}-" \
                            "#{Regexp.last_match(3)}")
          title = Regexp.last_match(4).tr("_", " ")
          [date, title, true]
        else
          [nil, basename.tr("_", " "), false]
        end
      rescue ArgumentError
        [nil, basename.tr("_", " "), false]
      end

      # Builds a URL-safe slug from filename
      # @param basename [String] the filename without extension
      # @return [String] the generated slug
      def build_slug(basename)
        s = basename.sub(/^\d{4}-\d{2}-\d{2}_/, "")
        if @config["slug_danish_map"]
          s = s.gsub(/[æøåÆØÅ]/,
                     { "æ" => "ae", "ø" => "oe", "å" => "aa", "Æ" => "Ae", "Ø" => "Oe",
                       "Å" => "Aa" })
        end
        s = s.downcase if @config["slug_downcase"]
        s = s.gsub(/[^\p{Alnum}\-_\s]/u, "").tr("_ ", "--").squeeze("-")
        s = s.sub(/^-+/, "").sub(/-+$/, "") # Remove leading/trailing hyphens
        s.empty? ? "untitled" : s
      end
    end
  end
end
