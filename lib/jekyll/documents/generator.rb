# frozen_string_literal: true

require "date"

module Jekyll
  module Documents
    # Main generator that scans document files and creates Jekyll collection items
    # @api public
    class Generator < ::Jekyll::Generator
      safe true
      priority :normal

      CONTENT_TYPES = {
        ".pdf" => "application/pdf",
        ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        ".odt" => "application/vnd.oasis.opendocument.text",
        ".ods" => "application/vnd.oasis.opendocument.spreadsheet",
        ".odp" => "application/vnd.oasis.opendocument.presentation"
      }.freeze

      private_constant :CONTENT_TYPES

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

        current_paths = []

        Dir.glob("#{root}/**/*").each do |path|
          next unless File.file?(path)

          ext = File.extname(path).downcase
          if @config["strict_extensions"] && !@config["include_extensions"].include?(ext)
            ::Jekyll.logger.abort_with "jekyll-documents",
                                       "Unsupported file type: #{path} (#{ext})"
          end
          next unless @config["include_extensions"].include?(ext)

          rel_path = path.delete_prefix("#{site.source}/")
          current_paths << rel_path
          category = infer_category_from(rel_path)
          basename = File.basename(path, ext)

          date, title, valid = parse_filename(basename)
          if !valid && @config["strict_filename"]
            ::Jekyll.logger.abort_with "jekyll-documents",
                                       "Filename must be 'YYYY-MM-DD_Title.ext' → #{rel_path}"
          end

          slug = build_slug(basename)
          file_type = ext.sub(".", "").downcase
          icon_set = @config["icon_set"]

          doc = ::Jekyll::Document.new(
            source_stub_for(basename, category),
            site: site,
            collection: collection
          )

          file_info = { title: title, date: date, category: category,
                        rel_path: rel_path, ext: ext, file_type: file_type,
                        icon_set: icon_set, slug: slug, path: path }
          bake_document_data(doc, file_info)
          collection.docs << doc
        end

        cleanup_manifest(current_paths) if @config["extract_text"]
        configure_client_search(site)
      end

      private

      # Auto-injects passthrough_fields into client_search config when the
      # documents collection is indexed. Only acts if client_search is already
      # configured with +documents+ in its collections list — does nothing if
      # jekyll-client-search is not installed or not used.
      def configure_client_search(site)
        search_config = site.config["client_search"]
        return unless search_config.is_a?(Hash)
        return unless Array(search_config["collections"]).include?("documents")

        fields = search_config["passthrough_fields"] || []
        existing = fields.flat_map { |f| f.is_a?(Hash) ? f.keys : [f.to_s] }
        %w[file_type icon_url icon_set].each do |field|
          fields << field unless existing.include?(field)
        end
        search_config["passthrough_fields"] = fields
        search_config["icon_field"] = "icon_url" unless search_config.key?("icon_field")
      end

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

      def searchable_content(title, data, file_type)
        date_str = data["date"].strftime("%Y-%m-%d")
        "#{title} #{data['category']} #{file_type} #{date_str}"
      end

      def extract_file_content(info)
        return nil unless load_plaintext

        content_type = CONTENT_TYPES[info[:ext]]
        return nil unless content_type

        manifest = text_manifest
        rel_path = info[:rel_path]
        digest = ::Digest::SHA256.file(info[:path]).hexdigest

        cached = manifest.get(rel_path, digest)
        return cached if cached

        # Suppress ActiveSupport deprecation warnings from the plaintext gem
        # (it uses String#mb_chars, deprecated in Rails 8.2).
        # We apply our own truncation below, so the gem's internal limit is redundant.
        text = ActiveSupport::Deprecation._instance.silence do
          ::Plaintext::Resolver.new(File.open(info[:path]), content_type).text
        end
        text = text&.truncate(@config["text_max_bytes"]) if text
        manifest.set(rel_path, digest, text) if text
        text
      rescue StandardError => e
        ::Jekyll.logger.warn "jekyll-documents",
                             "Text extraction failed for #{info[:path]}: #{e.message}"
        nil
      end

      def load_plaintext
        return true if defined?(::Plaintext)

        require "plaintext"
        true
      rescue LoadError
        ::Jekyll.logger.warn "jekyll-documents",
                             "extract_text is enabled but the 'plaintext' gem is not installed. " \
                             "Run: gem install plaintext"
        false
      end

      def text_manifest
        @text_manifest ||= TextExtractionManifest.new(@site, @config["text_cache_dir"])
      end

      def cleanup_manifest(current_rel_paths)
        text_manifest.cleanup_deleted(current_rel_paths)
        text_manifest.save
      end

      def bake_document_data(doc, info)
        data = doc.data
        category = remap_category(info[:category])
        data["layout"]     = @config["layout"]
        data["title"]      = info[:title]
        data["date"]       = info[:date] ? info[:date].to_time : File.mtime(info[:path])
        data["category"]   = category
        data["categories"] = [category] if category
        data["file_url"]   = "/#{info[:rel_path]}"
        data["extension"]  = info[:ext]
        data["file_type"]  = info[:file_type]
        data["icon_set"]   = info[:icon_set]
        icon = FileTypeIcons.icon_for(info[:file_type], info[:icon_set])
        data["icon_url"]   = icon
        data["file_size"]  = File.size(info[:path])
        data["slug"]       = info[:slug]
        data["permalink"]  = @config["permalink"]
                             .gsub(":category", category.to_s)
                             .gsub(":slug", info[:slug])
        doc.content = if @config["extract_text"]
                        extract_file_content(info) || searchable_content(info[:title], data,
                                                                         info[:file_type])
                      else
                        searchable_content(info[:title], data, info[:file_type])
                      end
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
          year = Regexp.last_match(1).to_i
          month = Regexp.last_match(2).to_i
          day = Regexp.last_match(3).to_i
          date = Date.new(year, month, day)
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
        slug = basename.sub(/^\d{4}-\d{2}-\d{2}_/, "")
        if @config["slug_danish_map"]
          slug = slug.gsub(/[æøåÆØÅ]/,
                           { "æ" => "ae", "ø" => "oe", "å" => "aa", "Æ" => "Ae", "Ø" => "Oe",
                             "Å" => "Aa" })
        end
        slug = slug.downcase if @config["slug_downcase"]
        slug = slug.gsub(/[^\p{Alnum}\-_\s]/u, "").tr("_ ", "--").squeeze("-")
        slug = slug.sub(/^-+/, "").sub(/-+$/, "")
        slug.empty? ? "untitled" : slug
      end
    end
  end
end
