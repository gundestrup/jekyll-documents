# frozen_string_literal: true

module Jekyll
  module Documents
    module ResolutionReporter
      private

      def report_resolution_issue(site, message)
        method = Configuration.read(site)["resolution_mode"].to_s == "strict" ? :abort_with : :warn
        ::Jekyll.logger.public_send(method, "jekyll-documents", message)
      end
    end

    class Configuration
      RESOLUTION_MODES = %w[warn strict].freeze
      private_constant :RESOLUTION_MODES

      DEFAULTS = {
        "root" => "assets/documents",
        "permalink" => "/documents/:category/:slug/",
        "slug_downcase" => true,
        "slug_danish_map" => true,
        "categories_from_path" => true,
        "include_extensions" => %w[.pdf .docx .pptx .xlsx .odt .ods .odp],
        "layout" => "document",
        "latest_default_count" => 5,

        # Icon configuration
        "icon_set" => "color",

        # Validation
        "strict_filename" => true,
        "strict_extensions" => true,
        "resolution_mode" => "warn",

        # JSON Index for Lunr
        "json_index" => true,
        "json_index_path" => "/documents.json",

        # Text extraction for search indexing (requires optional 'plaintext' gem)
        "extract_text" => false,
        "text_max_bytes" => 500_000,
        "text_cache_dir" => ".cache/jekyll-documents",

        # Optional category mapping
        "category_map" => {}
      }.freeze

      def self.read(site)
        cfg = DEFAULTS.merge(site.config["documents"] || {})
        mode = cfg["resolution_mode"].to_s
        unless RESOLUTION_MODES.include?(mode)
          ::Jekyll.logger.abort_with "jekyll-documents",
                                     "resolution_mode must be warn or strict, got #{mode.inspect}"
        end
        cfg
      end
    end
  end
end
