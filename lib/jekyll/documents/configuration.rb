# frozen_string_literal: true

module Jekyll
  module Documents
    class Configuration
      DEFAULTS = {
        "root" => "assets/documents",
        "permalink" => "/documents/:category/:slug/",
        "title_from_filename" => true,
        "slug_downcase" => true,
        "slug_danish_map" => true,
        "categories_from_path" => true,
        "include_extensions" => %w[.pdf .docx .pptx .xlsx .odt .ods .odp],
        "layout" => "document",
        "latest_default_count" => 5,

        # Validation
        "strict_filename" => true,
        "strict_extensions" => true,

        # JSON Index for Lunr
        "json_index" => true,
        "json_index_path" => "/documents.json",

        # Optional category mapping
        "category_map" => {}
      }.freeze

      def self.read(site)
        cfg = site.config["documents"] || {}
        DEFAULTS.merge(cfg)
      end
    end
  end
end
