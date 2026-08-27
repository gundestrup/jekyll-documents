# frozen_string_literal: true

require "json"
require "fileutils"
require "digest"

module Jekyll
  module Documents
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
      def get(rel_path, digest)
        entry = @manifest[rel_path]
        return nil unless entry
        return nil unless entry["digest"] == digest

        text_file = text_file_path(entry["text_file"])
        return nil unless File.file?(text_file)

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
      def set(rel_path, digest, text)
        text_file = write_text_file(digest, text)
        @manifest[rel_path] = {
          "digest" => digest,
          "text_file" => text_file,
          "extracted_at" => Time.now.to_i
        }
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

          entry = @manifest[rel_path]
          delete_text_file(entry["text_file"]) if entry
          @manifest.delete(rel_path)
          removed += 1
          @dirty = true
        end

        removed
      end

      # Save the manifest to disk if it has changed.
      # Uses atomic write (temp file + rename) to prevent corruption.
      # @return [void]
      def save
        return unless @dirty

        content = JSON.pretty_generate(@manifest)
        return if File.exist?(@manifest_path) && File.binread(@manifest_path) == content

        FileUtils.mkdir_p(@cache_root)
        temporary_path = "#{@manifest_path}.tmp-#{Process.pid}-#{Thread.current.object_id}"
        File.open(temporary_path, "wb") do |file|
          file.write(content)
          file.flush
          file.fsync
        end
        File.rename(temporary_path, @manifest_path)
      ensure
        FileUtils.rm_f(temporary_path) if defined?(temporary_path) && temporary_path
      end

      # Check if a document is in the manifest with a matching digest.
      # @param rel_path [String] relative path of the source document
      # @param digest [String] SHA-256 hex digest of the source file
      # @return [Boolean]
      def cached?(rel_path, digest)
        entry = @manifest[rel_path]
        !!(entry && entry["digest"] == digest)
      end

      # Number of entries in the manifest.
      # @return [Integer]
      def size
        @manifest.size
      end

      private

      def load_manifest
        return {} unless File.file?(@manifest_path)

        data = JSON.parse(File.read(@manifest_path, encoding: "UTF-8"))
        data.is_a?(Hash) ? data : {}
      rescue JSON::ParserError => e
        ::Jekyll.logger.warn "jekyll-documents",
                             "Corrupt text extraction manifest, starting fresh: #{e.message}"
        {}
      rescue StandardError
        {}
      end

      def text_file_path(text_file)
        File.join(@text_dir, text_file)
      end

      def write_text_file(digest, text)
        shard = digest[0, 2]
        subdir = File.join(@text_dir, shard)
        FileUtils.mkdir_p(subdir)
        filename = "#{digest}.txt"
        path = File.join(subdir, filename)
        File.write(path, text, encoding: "UTF-8")
        File.join(shard, filename)
      end

      def delete_text_file(text_file)
        return unless text_file

        path = text_file_path(text_file)
        File.delete(path) if File.file?(path)
      rescue StandardError
        nil
      end
    end
  end
end
