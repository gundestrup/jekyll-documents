# frozen_string_literal: true

require "json"
require "fileutils"
require "digest"

module Jekyll
  module Documents
    module TextExtractionManifestSupport
      private

      def load_manifest
        return {} unless File.file?(@manifest_path)

        data = JSON.parse(File.read(@manifest_path, encoding: "UTF-8"))
        data.is_a?(Hash) ? data.select { |_path, entry| valid_entry?(entry) } : {}
      rescue JSON::ParserError => e
        ::Jekyll.logger.warn "jekyll-documents",
                             "Corrupt text extraction manifest, starting fresh: #{e.message}"
        {}
      rescue StandardError => e
        ::Jekyll.logger.warn "jekyll-documents",
                             "Text extraction manifest read failed: #{e.message}"
        {}
      end

      def valid_entry?(entry)
        entry.is_a?(Hash) && entry.values_at("digest", "cache_key", "text_file").all?(String)
      end

      def cache_key(digest, metadata)
        Digest::SHA256.hexdigest(JSON.generate("digest" => digest, "metadata" => metadata))
      end

      def text_file_path(text_file)
        return unless text_file.is_a?(String)

        path = File.expand_path(File.join(@text_dir, text_file))
        root = File.expand_path(@text_dir)
        path.start_with?("#{root}#{File::SEPARATOR}") ? path : nil
      end

      def write_text_file(digest, text)
        shard = digest[0, 2]
        subdir = File.join(@text_dir, shard)
        FileUtils.mkdir_p(subdir)
        filename = "#{digest}.txt"
        File.write(File.join(subdir, filename), text, encoding: "UTF-8")
        File.join(shard, filename)
      end

      def cleanup_unreferenced_text_files
        referenced = @manifest.values.filter_map do |entry|
          text_file_path(entry["text_file"]) if valid_entry?(entry)
        end.to_set
        Dir.glob(File.join(@text_dir, "**", "*.txt")).each do |path|
          File.delete(path) unless referenced.include?(File.expand_path(path))
        end
      rescue StandardError
        nil
      end
    end

    # Manages the text extraction manifest — a persistent JSON file that tracks
    # which documents have had their text extracted, keyed by SHA-256 digest.
    #
    # The manifest lives in <site.source>/<cache_dir>/text-extraction-manifest.json
    # and extracted text is stored in separate files under <cache_dir>/text/
    # (sharded by the first 2 hex chars of the digest to avoid huge directories).
    #
    # This design borrows from jekyll-imgflow's ManifestManager:
    # - Atomic writes (temp file + rename)
    # - SHA-256 content digests for cache invalidation
    # - Cleanup of entries for deleted source files
    # - Survives `jekyll clean` (stored in site source, not .jekyll-cache/)
    class TextExtractionManifest
      include TextExtractionManifestSupport

      MANIFEST_FILENAME = "text-extraction-manifest.json"
      TEXT_SUBDIR = "text"

      attr_reader :manifest_path, :cache_dir

      # @param site [Jekyll::Site] the Jekyll site instance
      # @param cache_dir [String] relative path from site source for cache directory
      def initialize(site, cache_dir)
        @site = site
        @cache_dir = cache_dir
        @cache_root = File.join(site.source, cache_dir)
        @manifest_path = File.join(@cache_root, MANIFEST_FILENAME)
        @text_dir = File.join(@cache_root, TEXT_SUBDIR)
        @manifest = load_manifest
        @dirty = false
      end

      # Get cached text for a document if the digest matches.
      # @param rel_path [String] relative path of the source document
      # @param digest [String] SHA-256 hex digest of the source file
      # @return [String, nil] extracted text if cache hit, nil otherwise
      def get(rel_path, digest, metadata = {})
        entry = @manifest[rel_path]
        return nil unless valid_entry?(entry)
        return nil unless entry["cache_key"] == cache_key(digest, metadata)

        text_file = text_file_path(entry["text_file"])
        return nil unless text_file && File.file?(text_file)

        File.read(text_file, encoding: "UTF-8")
      rescue StandardError => e
        ::Jekyll.logger.warn "jekyll-documents",
                             "Manifest read failed for #{rel_path}: #{e.message}"
        nil
      end

      # Store extracted text for a document.
      # @param rel_path [String] relative path of the source document
      # @param digest [String] SHA-256 hex digest of the source file
      # @param text [String] the extracted text
      # @return [void]
      def set(rel_path, digest, text, metadata = {})
        text_file = write_text_file(digest, text)
        @manifest[rel_path] = {
          "digest" => digest,
          "cache_key" => cache_key(digest, metadata),
          "text_file" => text_file,
          "extracted_at" => Time.now.to_i
        }
        cleanup_unreferenced_text_files
        @dirty = true
      end

      # Remove manifest entries and their text files for source documents
      # that no longer exist.
      # @param current_rel_paths [Array<String>] relative paths of current source files
      # @return [Integer] number of entries removed
      def cleanup_deleted(current_rel_paths)
        current_set = current_rel_paths.to_set
        removed = 0

        @manifest.each_key do |rel_path|
          next if current_set.include?(rel_path)

          @manifest.delete(rel_path)
          removed += 1
          @dirty = true
        end
        cleanup_unreferenced_text_files

        removed
      end

      # Save the manifest to disk if it has changed.
      # Uses atomic write (temp file + rename) to prevent corruption.
      # @return [void]
      def save
        return unless @dirty

        content = JSON.pretty_generate(@manifest)
        if File.exist?(@manifest_path) && File.binread(@manifest_path) == content
          @dirty = false
          return
        end

        FileUtils.mkdir_p(@cache_root)
        temporary_path = "#{@manifest_path}.tmp-#{Process.pid}-#{Thread.current.object_id}"
        File.open(temporary_path, "wb") do |file|
          file.write(content)
          file.flush
          file.fsync
        end
        File.rename(temporary_path, @manifest_path)
        @dirty = false
      ensure
        FileUtils.rm_f(temporary_path) if defined?(temporary_path) && temporary_path
      end

      # Check if a document is in the manifest with a matching digest.
      # @param rel_path [String] relative path of the source document
      # @param digest [String] SHA-256 hex digest of the source file
      # @return [Boolean]
      def cached?(rel_path, digest, metadata = {})
        entry = @manifest[rel_path]
        !!(valid_entry?(entry) && entry["cache_key"] == cache_key(digest, metadata))
      end

      # Number of entries in the manifest.
      # @return [Integer]
      def size
        @manifest.size
      end
    end
  end
end
