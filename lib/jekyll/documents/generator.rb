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
        @text_manifest = nil

        root = File.join(site.source, @config["root"])
        unless Dir.exist?(root)
          ::Jekyll.logger.warn "jekyll-documents", "Directory not found: #{root}"
          return
        end

        collection = ensure_collection(site, "documents")
        current_paths = []
        generated_docs = []

        Dir.glob("#{root}/**/*").each do |path|
          next unless File.file?(path)

          source_extension = File.extname(path)
          ext = source_extension.downcase
          if @config["strict_extensions"] && !@config["include_extensions"].include?(ext)
            ::Jekyll.logger.abort_with "jekyll-documents",
                                       "Unsupported file type: #{path} (#{ext})"
          end
          next unless @config["include_extensions"].include?(ext)

          source_path = source_path_for(path, root)
          category_path = document_category_path(source_path)
          category = remap_category(category_path)
          rel_path = normalize_path(File.join(@config["root"], source_path))
          current_paths << rel_path
          basename = File.basename(path, source_extension)

          date, title, valid = parse_filename(basename)
          if !valid && @config["strict_filename"]
            ::Jekyll.logger.abort_with "jekyll-documents",
                                       "Filename must be 'YYYY-MM-DD_Title.ext' → #{rel_path}"
          end

          doc = ::Jekyll::Document.new(
            source_stub_for(source_path),
            site: site,
            collection: collection
          )
          file_info = {
            title: title, date: date, category: category, category_path: category_path,
            category_slug: slugify(category, "uncategorized"), source_path: source_path,
            rel_path: rel_path, ext: ext, file_type: ext.delete_prefix("."),
            icon_set: @config["icon_set"], slug: build_slug(basename), path: path
          }
          bake_document_data(doc, file_info)
          collection.docs << doc
          generated_docs << doc
        end

        detect_permalink_collisions(generated_docs)
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
        metadata = extraction_cache_metadata

        cached = manifest.get(rel_path, digest, metadata)
        return cached if cached

        configure_pdf_extractor(content_type)
        text = ActiveSupport.deprecator.silence do
          File.open(info[:path], "rb") do |file|
            ::Plaintext::Resolver.new(file, content_type).text
          end
        end
        text = truncate_bytes(text, @config["text_max_bytes"]) if text
        manifest.set(rel_path, digest, text, metadata) if text
        text
      rescue StandardError => e
        ::Jekyll.logger.warn "jekyll-documents",
                             "Text extraction failed for #{info[:path]}: #{e.message}"
        nil
      end

      def configure_pdf_extractor(content_type)
        return unless content_type == "application/pdf"
        return unless ::Plaintext::Configuration["pdftotext"].nil?

        executable = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR)
                        .map { |directory| File.join(directory, "pdftotext") }
                        .find { |path| File.executable?(path) }
        return unless executable

        ::Plaintext::Configuration.config["pdftotext"] =
          [executable, "-enc", "UTF-8", "__FILE__", "-"]
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

      def extraction_cache_metadata
        {
          "schema_version" => 1,
          "text_max_bytes" => @config["text_max_bytes"],
          "plaintext_version" => if ::Plaintext.const_defined?(:VERSION)
                                   ::Plaintext::VERSION.to_s
                                 else
                                   "unknown"
                                 end
        }
      end

      def truncate_bytes(text, max_bytes)
        bytes = text.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
                    .byteslice(0, max_bytes)
        bytes = bytes.to_s.force_encoding("UTF-8")
        bytes = bytes.byteslice(0, bytes.bytesize - 1) until bytes.valid_encoding?
        bytes
      end

      def cleanup_manifest(current_rel_paths)
        text_manifest.cleanup_deleted(current_rel_paths)
        text_manifest.save
      end

      def bake_document_data(doc, info)
        data = doc.data
        data["layout"]        = @config["layout"]
        data["title"]         = info[:title]
        data["date"]          = info[:date] ? info[:date].to_time : File.mtime(info[:path])
        data["category"]      = info[:category]
        data["category_path"] = info[:category_path]
        data["category_slug"] = info[:category_slug]
        data["categories"]    = [info[:category]] if info[:category]
        data["source_path"]   = info[:source_path]
        data["file_url"]      = "/#{info[:rel_path]}"
        data["extension"]     = info[:ext]
        data["file_type"]     = info[:file_type]
        data["icon_set"]      = info[:icon_set]
        data["icon_url"]      = FileTypeIcons.icon_for(info[:file_type], info[:icon_set])
        data["file_size"]     = File.size(info[:path])
        data["slug"]          = info[:slug]
        data["permalink"]     = expand_permalink(data)
        metadata_content = searchable_content(info[:title], data, info[:file_type])
        doc.content = if @config["extract_text"]
                        extracted_content = extract_file_content(info)
                        if extracted_content && !extracted_content.empty?
                          "#{metadata_content} #{extracted_content}"
                        else
                          metadata_content
                        end
                      else
                        metadata_content
                      end
      end

      # Creates a virtual source path for the document
      # @param source_path [String] the unique path below the documents root
      # @return [String] virtual source path
      def source_stub_for(source_path)
        File.join("_documents", "#{normalize_path(source_path)}.md")
      end

      # Infers category from the file's directory path
      # @param rel_path [String] relative path from site source
      # @return [String] the category name
      def infer_category_from(rel_path)
        return "uncategorized" unless @config["categories_from_path"]

        source_path = source_path_for(rel_path, @config["root"])
        category_path_for(source_path).split("/").last || "uncategorized"
      end

      # Remaps category name using category_map configuration
      # @param cat [String] the original category
      # @return [String] the mapped display category or lowercased directory name
      def remap_category(cat)
        map = @config["category_map"] || {}
        leaf = cat.to_s.split("/").last || "uncategorized"
        mapped = map[cat] || map[leaf]
        mapped ? mapped.to_s : leaf.downcase
      end

      def normalize_path(path)
        path.to_s.tr("\\", "/").squeeze("/").delete_prefix("/").delete_suffix("/")
      end

      def source_path_for(path, root)
        normalized_path = normalize_path(path)
        normalized_root = normalize_path(root)
        normalized_path.delete_prefix("#{normalized_root}/")
      end

      def category_path_for(source_path)
        path = normalize_path(source_path)
        path.include?("/") ? path.rpartition("/").first : "uncategorized"
      end

      def document_category_path(source_path)
        @config["categories_from_path"] ? category_path_for(source_path) : "uncategorized"
      end

      def expand_permalink(data)
        values = permalink_values(data)
        @config["permalink"].gsub(/:([a-z_]+)/) do |placeholder|
          values.fetch(Regexp.last_match(1), placeholder)
        end
      end

      def permalink_values(data)
        date = data["date"]
        {
          "category" => data["category_slug"],
          "category_path" => slugify_path(data["category_path"]),
          "slug" => data["slug"],
          "date" => date.strftime("%Y-%m-%d"),
          "year" => date.strftime("%Y"),
          "month" => date.strftime("%m"),
          "day" => date.strftime("%d"),
          "source_path" => source_path_url(data["source_path"])
        }
      end

      def slugify_path(path)
        normalize_path(path).split("/").map { |segment| slugify(segment, "untitled") }.join("/")
      end

      def source_path_url(source_path)
        extension = File.extname(source_path)
        stem = source_path.delete_suffix(extension)
        "#{slugify_path(stem)}#{extension.downcase}"
      end

      def detect_permalink_collisions(docs)
        collisions = docs.group_by(&:url).select { |_url, matches| matches.size > 1 }
        return if collisions.empty?

        details = collisions.sort.map do |url, matches|
          paths = matches.map { |doc| doc.data["source_path"] }.sort.join(", ")
          "#{url}: #{paths}"
        end
        ::Jekyll.logger.abort_with "jekyll-documents",
                                   "Permalink collision detected:\n#{details.join("\n")}"
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
        slugify(basename.sub(/^\d{4}-\d{2}-\d{2}_/, ""), "untitled")
      end

      def slugify(value, fallback)
        slug = value.to_s
        if @config["slug_danish_map"]
          slug = slug.gsub(/[æøåÆØÅ]/,
                           { "æ" => "ae", "ø" => "oe", "å" => "aa", "Æ" => "Ae", "Ø" => "Oe",
                             "Å" => "Aa" })
        end
        slug = slug.downcase if @config["slug_downcase"]
        slug = slug.gsub(/[^\p{Alnum}\-_\s]/u, "").tr("_ ", "--").squeeze("-")
        slug = slug.sub(/^-+/, "").sub(/-+$/, "")
        slug.empty? ? fallback : slug
      end
    end
  end
end
